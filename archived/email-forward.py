# by grok 4.1, not tested
import argparse
import asyncio
import smtplib
from aiosmtpd.controller import Controller

rules = """
*@896444.xyz->tmp1@recolic.net
root@recolic.cc->root@recolic.net
*@recolic.cc->tmp2@recolic.net
*->dustbin@recolic.net
"""

class RuleHandler:
    def __init__(self, rules_str, smtp_host, smtp_port):
        self.rules = self._parse_rules(rules_str)
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port

    def _parse_rules(self, rules_str):
        return [(pat.strip(), tgt.strip()) for line in rules_str.strip().split('\n')
                if '->' in line for pat, tgt in [line.split('->', 1)]]

    def get_target(self, sender):
        for pat, tgt in self.rules:
            if self._matches(pat, sender):
                return tgt
        return None

    def _matches(self, pat, sender):
        if pat == '*':
            return True
        if pat == sender:
            return True
        if pat.startswith('*@'):
            domain = pat[2:]
            return '@' in sender and sender.split('@', 1)[1] == domain
        return False

    async def handle_DATA(self, server, session, envelope):
        sender = envelope.sender
        target = self.get_target(sender)
        if not target:
            print(f"No rule for {sender}")
            return '550 No route to host'
        try:
            await asyncio.get_event_loop().run_in_executor(
                None, self._sync_forward, envelope.original_content, sender, target
            )
            print(f"Forwarded from {sender} to {target}")
            return '250 OK'
        except Exception as e:
            print(f"Forward failed: {e}")
            return '550 Internal error'

    def _sync_forward(self, msg_bytes, sender, target):
        with smtplib.SMTP(self.smtp_host, self.smtp_port) as smtp:
            smtp.sendmail(sender, [target], msg_bytes)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Naive rule-based email forwarder')
    parser.add_argument('--listen-host', default='0.0.0.0')
    parser.add_argument('--listen-port', type=int, default=2525)
    parser.add_argument('--smtp-host', default='localhost')
    parser.add_argument('--smtp-port', type=int, default=25)
    args = parser.parse_args()

    handler = RuleHandler(rules, args.smtp_host, args.smtp_port)
    print(f'Starting SMTP server on {args.listen_host}:{args.listen_port}, forwarding via {args.smtp_host}:{args.smtp_port}')
    controller = Controller(handler, hostname=args.listen_host, port=args.listen_port)
    controller.start()

