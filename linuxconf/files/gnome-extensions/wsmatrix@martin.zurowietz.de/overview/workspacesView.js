import Clutter from 'gi://Clutter';
import Override from '../Override.js';
import {FitMode, WorkspacesView as GWorkspacesView} from 'resource:///org/gnome/shell/ui/workspacesView.js';

const _getFirstFitAllWorkspaceBox = function (box, spacing, vertical) {
    const workspaceManager = global.workspace_manager;
    const rows = workspaceManager.layout_rows;
    const columns = workspaceManager.layout_columns;

    const [width, height] = box.get_size();
    const [workspace] = this._workspaces;

    const fitAllBox = new Clutter.ActorBox();

    let [x1, y1] = box.get_origin();

    // Spacing here is not only the space between workspaces, but also the
    // space before the first workspace, and after the last one. This prevents
    // workspaces from touching the edges of the allocation box.
    const availableWidth = width - spacing * (columns + 1);
    const availableHeight = height - spacing * (rows + 1);
    let workspaceWidth = availableWidth / columns;
    let workspaceHeight = availableHeight / rows;
    let [, wh] = workspace.get_preferred_height(workspaceWidth);
    let [, ww] = workspace.get_preferred_width(workspaceHeight);
    if (wh < workspaceHeight) {
        workspaceHeight = wh;
    } else {
        workspaceWidth = ww;
    }

    fitAllBox.set_size(workspaceWidth, height);
    fitAllBox.set_origin(width / 2 - (workspaceWidth + spacing) * columns / 2, -rows / 2 * workspaceHeight);

    return fitAllBox;
}

const vfunc_allocate = function (box) {
    this.set_allocation(box);
    const workspaceManager = global.workspace_manager;
    const rows = workspaceManager.layout_rows;
    const columns = workspaceManager.layout_columns;

    if (this._workspaces.length === 0)
        return;

    const vertical = global.workspaceManager.layout_rows === -1;
    const rtl = this.text_direction === Clutter.TextDirection.RTL;

    const fitMode = this._fitModeAdjustment.value;

    let [fitSingleBox, fitAllBox] = this._getInitialBoxes(box);
    const fitSingleSpacing =
        this._getSpacing(fitSingleBox, FitMode.SINGLE, vertical);
    fitSingleBox =
        this._getFirstFitSingleWorkspaceBox(fitSingleBox, fitSingleSpacing, vertical);

    const fitAllSpacing =
        this._getSpacing(fitAllBox, FitMode.ALL, vertical);
    fitAllBox =
        this._getFirstFitAllWorkspaceBox(fitAllBox, fitAllSpacing, vertical);

    // Account for RTL locales by reversing the list
    const workspaces = this._workspaces.slice();
    if (rtl)
        workspaces.reverse();

    const [fitSingleX1, fitSingleY1] = fitSingleBox.get_origin();
    const [fitSingleWidth, fitSingleHeight] = fitSingleBox.get_size();
    const [fitAllX1, fitAllY1] = fitAllBox.get_origin();
    const [fitAllWidth, fitAllHeight] = fitAllBox.get_size();

    workspaces.forEach((child, i) => {
        if (fitMode === FitMode.SINGLE)
            box = fitSingleBox;
        else if (fitMode === FitMode.ALL)
            box = fitAllBox;
        else
            box = fitSingleBox.interpolate(fitAllBox, fitMode);

        child.allocate_align_fill(box, 0.5, 0.5, false, false);

        const targetRow = Math.floor((1+i) / columns);
        const targetColumn = (1+i) % columns;

        fitSingleBox.set_origin(
            fitSingleBox.x1 + fitSingleWidth + fitSingleSpacing,
            fitSingleY1);
        // TODO Alternative to the previous line that also displays the large
        // workspaces in the overview in a grid. The animation has to be fixed,
        // though and the view does not always move to the correct position.
        // fitSingleBox.set_origin(
        //     fitSingleX1 + (fitSingleWidth + fitSingleSpacing) * targetColumn,
        //     fitSingleY1 + (fitSingleHeight + fitSingleSpacing) * targetRow);

        let [, h] = child.get_preferred_height(fitAllWidth)
        fitAllBox.set_origin(
            fitAllX1 + (fitAllWidth + fitAllSpacing) * targetColumn,
            fitAllY1 + (h + fitAllSpacing) * targetRow);
    });
}


export default class WorkspacesView extends Override {
    enable() {
        const subject = GWorkspacesView.prototype;
        this._im.overrideMethod(subject, '_getFirstFitAllWorkspaceBox', (original) => {
            return function () {
                return _getFirstFitAllWorkspaceBox.call(this, ...arguments);
            };
        });

        this._im.overrideMethod(subject, 'vfunc_allocate', (original) => {
            return function () {
                return vfunc_allocate.call(this, ...arguments);
            };
        });
    }
}
