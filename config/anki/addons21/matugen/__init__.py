"""
Anki Matugen Integration Addon (Material You)
Loads matugen-generated colors into Anki's Qt widgets and webviews,
and watches for live changes when theme-switch runs.
"""

import os
import json
from aqt import mw, gui_hooks
from aqt.qt import QFileSystemWatcher, QTimer

CACHE_DIR = os.path.expanduser("~/.cache/matugen")
WEBVIEW_CSS = os.path.join(CACHE_DIR, "anki-webview.css")
QT_QSS = os.path.join(CACHE_DIR, "anki-qt.qss")
TRIGGER_FILE = os.path.join(CACHE_DIR, "anki-reload")


def read_cache(path: str) -> str:
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception:
            pass
    return ""


def on_webview_will_set_content(web_content, context) -> None:
    css = read_cache(WEBVIEW_CSS)
    if css:
        web_content.head += f"<style id='matugen-theme'>{css}</style>"


def on_style_did_init(buf: str) -> str:
    qss = read_cache(QT_QSS)
    if qss:
        return buf + "\n" + qss
    return buf


# Register initial hooks
gui_hooks.webview_will_set_content.append(on_webview_will_set_content)
gui_hooks.style_did_init.append(on_style_did_init)

# Live reload logic
_watcher = None
_timer = None


def apply_theme_now() -> None:
    if not mw:
        return

    # 1. Reapply Qt widgets stylesheet (menus, dialogs, statusbar)
    qss = read_cache(QT_QSS)
    if qss and hasattr(mw, "app") and mw.app:
        mw.app.setStyleSheet(qss)

    # 2. Inject updated webview CSS into all active AnkiWebView instances via JS
    css = read_cache(WEBVIEW_CSS)
    if css:
        from aqt.webview import AnkiWebView
        try:
            views = mw.findChildren(AnkiWebView)
            js = f"""
            (() => {{
                let el = document.getElementById('matugen-theme');
                if (!el) {{
                    el = document.createElement('style');
                    el.id = 'matugen-theme';
                    document.head.appendChild(el);
                }}
                el.textContent = {json.dumps(css)};
            }})();
            """
            for view in views:
                try:
                    view.eval(js)
                except Exception:
                    pass
        except Exception:
            pass

    # 3. Redraw top toolbar (Decks, Add, Browse, Stats, Sync)
    if hasattr(mw, "toolbar") and mw.toolbar:
        try:
            mw.toolbar.draw()
        except Exception:
            pass

    # 4. Refresh active main view (deck browser, reviewer, or overview)
    if hasattr(mw, "state"):
        if mw.state == "deckBrowser" and hasattr(mw, "deckBrowser") and mw.deckBrowser:
            mw.deckBrowser.refresh()
        elif mw.state == "review" and hasattr(mw, "reviewer") and mw.reviewer:
            mw.reviewer.refresh()
        elif mw.state == "overview" and hasattr(mw, "overview") and mw.overview:
            mw.overview.refresh()
        else:
            if hasattr(mw, "reset"):
                mw.reset()


def setup_live_reload() -> None:
    global _watcher, _timer
    if not os.path.exists(CACHE_DIR):
        return

    _timer = QTimer()
    _timer.setSingleShot(True)
    _timer.setInterval(50)  # 50ms debounce for batch writes
    _timer.timeout.connect(apply_theme_now)

    _watcher = QFileSystemWatcher()
    _watcher.addPath(CACHE_DIR)
    for p in (WEBVIEW_CSS, QT_QSS, TRIGGER_FILE):
        if os.path.exists(p):
            _watcher.addPath(p)

    def on_change(_path: str) -> None:
        if _watcher:
            for p in (WEBVIEW_CSS, QT_QSS, TRIGGER_FILE):
                if os.path.exists(p) and p not in _watcher.files():
                    _watcher.addPath(p)
        if _timer:
            _timer.start()

    _watcher.directoryChanged.connect(on_change)
    _watcher.fileChanged.connect(on_change)


gui_hooks.main_window_did_init.append(setup_live_reload)
