from textual import on
from textual.app import App, ComposeResult
from textual.widgets import Button, Footer, Header, Static


import subprocess
from subprocess import PIPE
import sys
import time


class Dependinst(Static):

    @on(Button.Pressed, "dependinst")
    def a_method(self) -> ComposeResult:
        subprocess.run(["./test.sh"])
        yield Static("完了しました")

    def compose(self):
        yield Button("依存関係インストール", id="dependinst")
        yield Button("ノードインストール", id="nodeinst")


class PocApp(App):
    BINDINGS = [
        ("d", "toggle_dark_mode", "ダークモード切替"),
    ]

    def compose(self):
        yield Header(show_clock=True)
        yield Footer()
        yield Dependinst()

    def action_toggle_dark_mode(self):
        self.dark = not self.dark


if __name__ == "__main__":
    PocApp().run()
