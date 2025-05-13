/* -*- mode: js2; js2-basic-offset: 4; indent-tabs-mode: nil -*- */

'use strict';

import GObject from "gi://GObject";
import Gtk from "gi://Gtk";
import Gio from "gi://Gio";
import Gdk from "gi://Gdk";
import Adw from "gi://Adw";

import { ExtensionPreferences, gettext as _ } from "resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js";

import { check_sensors } from './common.js';

const N_ = function (e) {
    return e;
};

function sm_log(message) {
    console.log(`[system-monitor-next-prefs] ${message}`);
}

String.prototype.capitalize = function () {
    return this.replace(/(^|\s)([a-z])/g, function (m, p1, p2) {
        return p1 + p2.toUpperCase();
    });
};

function color_to_hex(color) {
    var output = N_('#%02x%02x%02x%02x').format(
        255 * color.red,
        255 * color.green,
        255 * color.blue,
        255 * color.alpha);
    return output;
}

// ** General Preferences Page **
const SMGeneralPrefsPage = GObject.registerClass({
    GTypeName: 'SMGeneralPrefsPage',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsGeneralSettings.ui'),
    InternalChildren: ['background', 'icon_display', 'show_tooltip', 'move_clock',
        'compact_display', 'center_display', 'left_display', 'rotate_labels',
        'tooltip_delay_ms', 'custom_monitor_switch', 'custom_monitor_command'],
}, class SMGeneralPrefsPage extends Adw.PreferencesPage {
    constructor(settings, params = {}) {
        super(params);

        this._settings = settings;

        let color = new Gdk.RGBA();
        color.parse(this._settings.get_string('background'));
        this._background.set_rgba(color);

        let colorDialog = new Gtk.ColorDialog({
            modal: true,
            with_alpha: true,
        });
        this._background.set_dialog(colorDialog);

        this._background.connect('notify::rgba', colorButton => {
            this._settings.set_string('background', color_to_hex(colorButton.get_rgba()));
        });
        this._settings.connect('changed::background', () => {
            color.parse(this._settings.get_string('background'));
            this._background.set_rgba(color);
        });

        this._settings.bind('icon-display', this._icon_display,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind('show-tooltip', this._show_tooltip,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind('move-clock', this._move_clock,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind('compact-display', this._compact_display,
            'active', Gio.SettingsBindFlags.DEFAULT
        );

        this._settings.bind('center-display', this._center_display,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind('left-display', this._left_display,
            'active', Gio.SettingsBindFlags.DEFAULT
        );

        // to alternately disable positioning options
        this._center_display.connect('notify::active', () => {
            if (this._center_display.active) {
                this._settings.set_boolean('left-display', false);
            }
        })
        this._left_display.connect('notify::active', () => {
            if (this._left_display.active) {
                this._settings.set_boolean('center-display', false);
            }
        })

        this._settings.bind('rotate-labels', this._rotate_labels,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind('tooltip-delay-ms', this._tooltip_delay_ms,
            'value', Gio.SettingsBindFlags.DEFAULT
        );

        const hasCommand = this._settings.get_string('custom-monitor-command').trim() !== '';
        this._custom_monitor_switch.active = hasCommand;
        this._custom_monitor_command.visible = hasCommand;

        this._custom_monitor_switch.connect('notify::active', () => {
            this._custom_monitor_command.visible = this._custom_monitor_switch.active;
            if (!this._custom_monitor_switch.active) {
                this._settings.set_string('custom-monitor-command', '');
            }
        });

        this._settings.bind('custom-monitor-command', this._custom_monitor_command,
            'text', Gio.SettingsBindFlags.DEFAULT
        );
    }
});

// ** Widget Position Preferences Page **
// the code of this preferences page is an adaptation of the "Top Bar Organizer" code.
// https://gitlab.gnome.org/julianschacher/top-bar-organizer
const SMWidgetPosPrefsItem = GObject.registerClass({
    GTypeName: 'SMWidgetPosPrefsItem',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsWidgetPositionItem.ui'),
    Signals: {
        'move': {param_types: [GObject.TYPE_STRING]},
    },
}, class SMWidgetPosPrefsItem extends Adw.ActionRow {
    static {
        this.install_action('row.move-up', null, (self, _actionName, _param) => self.emit('move', 'up'));
        this.install_action('row.move-down', null, (self, _actionName, _param) => self.emit('move', 'down'));
    }

    constructor(settings, widgetType, params = {}) {
        super(params);

        this._settings = settings;
        this._widgetType = widgetType;

        this.title = _(this._widgetType.capitalize());

        this._drag_starting_point_x = 0;
        this._drag_starting_point_y = 0;
    }

    onDragPrepare(_source, x, y) {
        const value = new GObject.Value();
        value.init(SMWidgetPosPrefsItem);
        value.set_object(this);

        this._drag_starting_point_x = x;
        this._drag_starting_point_y = y;
        return Gdk.ContentProvider.new_for_value(value);
    }

    onDragBegin(_source, drag) {
        let dragWidget = new Gtk.ListBox();
        dragWidget.set_size_request(this.get_width(), this.get_height());

        let dragSMWidgetPosPrefsItem = new SMWidgetPosPrefsItem(this._settings, this._widgetType, {});
        dragWidget.append(dragSMWidgetPosPrefsItem);
        dragWidget.drag_highlight_row(dragSMWidgetPosPrefsItem);

        let currentDragIcon = Gtk.DragIcon.get_for_drag(drag);
        currentDragIcon.set_child(dragWidget);
        drag.set_hotspot(this._drag_starting_point_x, this._drag_starting_point_y);
    }

    // Handle a new drop on `this` properly. `value` is the thing getting dropped.
    onDrop(_target, value, _x, _y) {
        // If `this` got dropped onto itself, do nothing.
        if (value === this)
            return;

        // Get the ListBox.
        const listBox = this.get_parent();

        // Get the position of `this` and the drop value.
        const ownPosition = this.get_index();
        const valuePosition = value.get_index();

        // Remove the drop value from its list box.
        listBox.removeRow(value);

        // Since drop value was removed get the position of `this` again.
        const updatedOwnPosition = this.get_index();

        if (valuePosition < ownPosition) {
            // If the drop value was before `this`, add the drop value after `this`.
            listBox.insertRow(value, updatedOwnPosition + 1);
        } else {
            // Otherwise, add the drop value where `this` currently is.
            listBox.insertRow(value, updatedOwnPosition);
        }

        // Save the widgets order to settings and make sure move
        // actions are correctly enabled/disabled.
        listBox.saveWidgetsPositionToSettings();
        listBox.determineRowMoveActionEnable();
    }
});

const SMWidgetPosPrefsListBox = GObject.registerClass({
    GTypeName: 'SMWidgetPosPrefsListBox',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsWidgetPositionList.ui'),
    Signals: {
        'row-move': {param_types: [SMWidgetPosPrefsItem, GObject.TYPE_STRING]},
    },
}, class SMWidgetPosPrefsListBox extends Gtk.ListBox {
    constructor(settings, params = {}) {
        super(params);

        this._settings = settings;
        this._rowSignalHandlerIds = new Map();

        let widgetTypes = [
            'cpu',
            'freq',
            'memory',
            'swap',
            'net',
            'disk',
            'gpu',
            'thermal',
            'fan',
            'battery',
        ];

        widgetTypes.forEach(widgetType => {
            let item = new SMWidgetPosPrefsItem(settings, widgetType);
            let position = this._settings.get_int(`${widgetType}-position`);
            this.insertRow(item, position);
        });

        this.determineRowMoveActionEnable();
    }

    // Inserts the given SMWidgetPosPrefsItem to this at the given position.
    // Also handles stuff like connecting signals.
    insertRow(row, position) {
        this.insert(row, position);

        const signalHandlerIds = [];

        signalHandlerIds.push(row.connect('move', (row, direction) => {
            this.emit('row-move', row, direction);
        }));

        this._rowSignalHandlerIds.set(row, signalHandlerIds);
    }

    // Removes the given SMWidgetPosPrefsItem from this.
    // Also handles stuff like disconnecting signals.
    removeRow(row) {
        const signalHandlerIds = this._rowSignalHandlerIds.get(row);

        for (const id of signalHandlerIds)
            row.disconnect(id);

        this.remove(row);
    }

    // Save the widgets order to settings.
    saveWidgetsPositionToSettings() {
        let currentWidgetsOrder = [];

        for (let potentialSMWidgetPosPrefsItem of this) {
            // Only process SMWidgetPosPrefsItem.
            if (potentialSMWidgetPosPrefsItem.constructor.$gtype.name !== 'SMWidgetPosPrefsItem')
                continue;

            currentWidgetsOrder.push(potentialSMWidgetPosPrefsItem._widgetType);
        }

        currentWidgetsOrder.forEach(widgetType => {
            this._settings.set_int(`${widgetType}-position`, currentWidgetsOrder.indexOf(widgetType));
        });
    }

    // Determines whether or not each move action of each SMWidgetPosPrefsItem should be enabled or disabled.
    determineRowMoveActionEnable() {
        for (let potentialSMWidgetPosPrefsItem of this) {
            // Only process SMWidgetPosPrefsItem.
            if (potentialSMWidgetPosPrefsItem.constructor.$gtype.name !== 'SMWidgetPosPrefsItem')
                continue;


            const row = potentialSMWidgetPosPrefsItem;

            // If the current row is the topmost row then disable the move-up action.
            if (row.get_index() === 0)
                row.action_set_enabled('row.move-up', false);
            else // Else enable it.
                row.action_set_enabled('row.move-up', true);

            // If the current row is the bottommost row then disable the move-down action.
            const rowNextSibling = row.get_next_sibling();
            if (rowNextSibling === null)
                row.action_set_enabled('row.move-down', false);
            else // Else enable it.
                row.action_set_enabled('row.move-down', true);
        }
    }
});

const SMWidgetPosPrefsPage = GObject.registerClass({
    GTypeName: 'SMWidgetPosPrefsPage',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsWidgetPositionPrefsPage.ui'),
    InternalChildren: ['widget_position_group'],
}, class SMWidgetPosPrefsPage extends Adw.PreferencesPage {
    constructor(settings, params = {}) {
        super(params);

        let widgetListBox = new SMWidgetPosPrefsListBox(settings);
        widgetListBox.set_css_classes(['boxed-list']);
        widgetListBox.connect('row-move', this.onRowMove);
        this._widget_position_group.add(widgetListBox);
    }

    onRowMove(listBox, row, direction) {
        const rowPosition = row.get_index();

        if (direction === 'up') {
            if (rowPosition !== 0) {
                listBox.removeRow(row);
                listBox.insertRow(row, rowPosition - 1);
                listBox.saveWidgetsPositionToSettings();
                listBox.determineRowMoveActionEnable();
            }
        } else {
            const rowNextSibling = row.get_next_sibling();
            if (rowNextSibling !== null) {
                listBox.removeRow(row);
                listBox.insertRow(row, rowPosition + 1);
                listBox.saveWidgetsPositionToSettings();
                listBox.determineRowMoveActionEnable();
            }
        }
    }
});

// ** Widget Preferences Page **
const SMExpanderRow = GObject.registerClass({
    GTypeName: 'SMExpanderRow',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsExpanderRow.ui'),
    InternalChildren: ['display', 'show_menu', 'show_text', 'style', 'graph_width', 'refresh_time'],
}, class SMExpanderRow extends Adw.ExpanderRow {
    constructor(settings, widgetType, params = {}) {
        super(params);

        this._settings = settings;

        this.title = _(widgetType.capitalize());

        this._color = new Gdk.RGBA();
        this._colorDialog = new Gtk.ColorDialog({
            modal: true,
            with_alpha: true,
        });

        this._settings.bind(`${widgetType}-display`, this._display,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind(`${widgetType}-show-menu`, this._show_menu,
            'active', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind(`${widgetType}-show-text`, this._show_text,
            'active', Gio.SettingsBindFlags.DEFAULT
        );

        this._style.set_selected(this._settings.get_enum(`${widgetType}-style`));
        this._style.connect('notify::selected', widget => {
            this._settings.set_enum(`${widgetType}-style`, widget.selected);
        });

        this._settings.bind(`${widgetType}-graph-width`, this._graph_width,
            'value', Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind(`${widgetType}-refresh-time`, this._refresh_time,
            'value', Gio.SettingsBindFlags.DEFAULT
        );

        switch (widgetType) {
            case 'cpu': {
                let cpuColors = [
                    'cpu-user-color',
                    'cpu-iowait-color',
                    'cpu-nice-color',
                    'cpu-system-color',
                    'cpu-other-color',
                ];

                this._addColorsItem(cpuColors);

                let item = new Adw.SwitchRow({title: _('Display Individual Cores')});
                this._settings.bind('cpu-individual-cores', item,
                    'active', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);
                break;
            }
            case 'freq': {
                let freqColors = [
                    'freq-freq-color',
                ];

                this._addColorsItem(freqColors);

                let stringListModel = new Gtk.StringList();
                stringListModel.append(_('Max across all cores'));
                stringListModel.append(_('Average across all cores'));

                let displayModeRow = new Adw.ComboRow({
                    title: _('Value'),
                    model: stringListModel,
                    selected: this._settings.get_enum('freq-display-mode')
                });

                displayModeRow.connect('notify::selected', widget => {
                    this._settings.set_enum('freq-display-mode', widget.selected);
                });

                this.add_row(displayModeRow);
                break;
            }
            case 'memory': {
                let memoryColors = [
                    'memory-program-color',
                    'memory-buffer-color',
                    'memory-cache-color',
                ];

                this._addColorsItem(memoryColors);
                break;
            }
            case 'swap': {
                let swapColors = [
                    'swap-used-color',
                ];

                this._addColorsItem(swapColors);
                break;
            }
            case 'net': {
                let netColors = [
                    'net-down-color',
                    'net-up-color',
                    'net-downerrors-color',
                    'net-uperrors-color',
                    'net-collisions-color',
                ];

                this._addColorsItem(netColors);

                let item = new Adw.SwitchRow({title: _('Show network speed in bits')});
                this._settings.bind('net-speed-in-bits', item,
                    'active', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);
                break;
            }
            case 'disk': {
                let diskColors = [
                    'disk-read-color',
                    'disk-write-color',
                ];

                this._addColorsItem(diskColors);

                let stringListModel = new Gtk.StringList();
                stringListModel.append(_('pie'));
                stringListModel.append(_('bar'));
                stringListModel.append(_('none'));

                let item = new Adw.ComboRow({title: _('Usage Style')});
                item.set_model(stringListModel);

                item.set_selected(this._settings.get_enum('disk-usage-style'));
                item.connect('notify::selected', widget => {
                    this._settings.set_enum('disk-usage-style', widget.selected);
                });
                this.add_row(item);
                break;
            }
            case 'gpu': {
                let gpuColors = [
                    'gpu-used-color',
                    'gpu-memory-color',
                ];

                this._addColorsItem(gpuColors);
                break;
            }
            case 'thermal': {
                let thermalColors = [
                    'thermal-tz0-color',
                ];

                const labels = Object.keys(check_sensors('temp'));
                let stringListModel = new Gtk.StringList();

                if (labels.length === 0)
                    stringListModel.append(_('No temperature sensors found'));
                else if (labels.length === 1)
                    this._settings.set_string('thermal-sensor-label', labels[0]);

                labels.forEach(str => {
                    stringListModel.append(str);
                });

                let item = new Adw.ComboRow({title: _('Sensor:')});
                item.set_model(stringListModel);

                try {
                    item.set_selected(labels.indexOf(this._settings.get_string('thermal-sensor-label')));
                } catch (e) {
                    item.set_selected(0);
                }

                item.connect('notify::selected', widget => {
                    this._settings.set_string('thermal-sensor-label', labels[widget.selected]);
                });
                this.add_row(item);
                this._addColorsItem(thermalColors);

                item = new Adw.SpinRow({
                    title: _('Temperature threshold (0 to disable)'),
                    adjustment: new Gtk.Adjustment({
                        value: 0,
                        lower: 0,
                        upper: 300,
                        step_increment: 5,
                        page_increment: 10,
                    }),
                });
                item.set_numeric(true);
                item.set_update_policy(Gtk.UPDATE_IF_VALID);
                this._settings.bind('thermal-threshold', item,
                    'value', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);

                item = new Adw.SwitchRow({title: _('Display temperature in Fahrenheit')});
                this._settings.bind('thermal-fahrenheit-unit', item,
                    'active', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);
                break;
            }
            case 'fan': {
                let fanColors = [
                    'fan-fan0-color',
                ];

                this._addColorsItem(fanColors);

                const labels = Object.keys(check_sensors('fan'));
                let stringListModel = new Gtk.StringList();

                if (labels.length === 0)
                    stringListModel.append(_('No fan sensors found'));
                else if (labels.length === 1)
                    this._settings.set_string('fan-sensor-label', labels[0]);

                labels.forEach(str => {
                    stringListModel.append(str);
                });

                let item = new Adw.ComboRow({title: _('Sensor:')});
                item.set_model(stringListModel);

                try {
                    item.set_selected(labels.indexOf(this._settings.get_string('fan-sensor-label')));
                } catch (e) {
                    item.set_selected(0);
                }

                item.connect('notify::selected', widget => {
                    this._settings.set_string('fan-sensor-label', labels[widget.selected]);
                });
                this.add_row(item);
                break;
            }
            case 'battery': {
                let batteryColors = [
                    'battery-batt0-color',
                ];

                this._addColorsItem(batteryColors);

                let item = new Adw.SwitchRow({title: _('Show Time Remaining')});
                this._settings.bind('battery-time', item,
                    'active', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);

                item = new Adw.SwitchRow({title: _('Hide System Icon')});
                this._settings.bind('battery-hidesystem', item,
                    'active', Gio.SettingsBindFlags.DEFAULT
                );
                this.add_row(item);
                break;
            }
            default:
                break;
        }
    }

    _addColorsItem(colors) {
        colors.forEach(color => {
            let actionRow = new Adw.ActionRow({title: color.split('-')[1].capitalize()});
            let colorItem = new Gtk.ColorDialogButton({valign: Gtk.Align.CENTER});

            this._color.parse(this._settings.get_string(color));
            colorItem.set_rgba(this._color);
            colorItem.set_dialog(this._colorDialog);

            colorItem.connect('notify::rgba', colorButton => {
                this._settings.set_string(color, color_to_hex(colorButton.get_rgba()));
            });
            this._settings.connect(`changed::${color}`, () => {
                this._color.parse(this._settings.get_string(color));
                colorItem.set_rgba(this._color);
            });

            actionRow.add_suffix(colorItem);
            this.add_row(actionRow);
        });
    }
});

const SMWidgetPrefsPage = GObject.registerClass({
    GTypeName: 'SMWidgetPrefsPage',
    Template: import.meta.url.replace('prefs.js', 'ui/prefsWidgetSettings.ui'),
    InternalChildren: ['widget_prefs_group'],
}, class SMWidgetPrefsPage extends Adw.PreferencesPage {
    constructor(settings, params = {}) {
        super(params);

        let widgetNames = [
            'cpu',
            'freq',
            'memory',
            'swap',
            'net',
            'disk',
            'gpu',
            'thermal',
            'fan',
            'battery',
        ];

        widgetNames.forEach(widgetName => {
            let item = new SMExpanderRow(settings, widgetName);
            this._widget_prefs_group.add(item);
        });
    }
});

// ** Extension Preferences **
export default class SystemMonitorExtensionPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        let settings = this.getSettings();

        let generalSettingsPage = new SMGeneralPrefsPage(settings);
        window.add(generalSettingsPage);

        let widgetPositionSettingsPage = new SMWidgetPosPrefsPage(settings);
        window.add(widgetPositionSettingsPage);

        let widgetPreferencesPage = new SMWidgetPrefsPage(settings);
        window.add(widgetPreferencesPage);

        window.set_title(_('System Monitor Next Preferences'));
        window.search_enabled = true;
        window.set_default_size(645, 715);
    }
}
