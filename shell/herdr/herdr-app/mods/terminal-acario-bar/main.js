// Terminal-acario layout's draggable top bar: space picker, tabs, and window controls.

import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, run, theme, home, openOverlay, layout, window as win } from "herdr";

const C = {
  tray: "#e4e4ed",
  // The shown tab stands out; a hovered one only hints, so the two never look alike.
  tab: "#ffffff",
  tabEdge: "#c9cbd8",
  hover: "#0000000a",
  edge: "#d3d4e0",
  chip: "#ededf4",
  text: "#0F1019",
  dim: "#4d5060",
};

function find(node, id) {
  if (!node) return null;
  if (node.id === id) return node;
  for (const c of node.children ?? []) {
    const f = find(c, id);
    if (f) return f;
  }
  return null;
}

function folder(cwd) {
  if (!cwd) return "";
  const h = home();
  if (cwd === h) return "~";
  // Last path segment only ("/Volumes/dev/work" -> "work").
  return cwd.split("/").filter(Boolean).pop() ?? cwd;
}

// The pane a tab's tab speaks for: the focused one, else its agent, else the first.
function lead(all, id) {
  const mine = all.filter((p) => p.tab === id);
  return mine.find((p) => p.focused) ?? mine.find((p) => p.program?.agent) ?? mine[0];
}

// The program's tile from the app's table: its color, its glyph (or logo) on it.
function tile(t, p) {
  const g = p?.program;
  const dot = p?.status && p.status !== "idle" ? t[p.status] : null;
  return div()
    .relative()
    .flex_none()
    .w(26)
    .h(26)
    .rounded(7)
    .bg("#00000000")
    .flex()
    .items_center()
    .justify_center()
    .when(Boolean(g?.icon), (el) =>
      el.child(g.tint ? svg(g.icon).size(15).text_color(C.text) : image(g.icon).w(15).h(15)),
    )
    .when(Boolean(dot), (el) =>
      el.child(div().absolute().top(-4).right(-4).w(11).h(11).rounded_full().border_2().border_color(C.tray).bg(dot)),
    );
}

// A control in the draggable bar: the press is its own, not the window's
// (a right press there would open the system's window menu).
function own(el) {
  return el.on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_mouse_down("right", (_e, cx) => cx.stop_propagation());
}

function windowButton(id, icon, command) {
  return own(
    div()
      .id(id)
      .flex_none()
      .w(24)
      .h(24)
      .rounded_full()
      .flex()
      .items_center()
      .justify_center()
      .bg(C.chip)
      .text_color(C.dim)
      .cursor_pointer()
      .hover((s) => s.bg(C.edge).text_color(C.text))
      .on_click(() => run(command))
      .child(svg(`mods/terminal-acario-bar/${icon}.svg`).size(14)),
  );
}

function iconButton(id, icon, onClick) {
  return own(div())
    .id(id)
    .flex_none()
    .p(7)
    .rounded(8)
    .text_color(C.dim)
    .cursor_pointer()
    .hover((s) => s.bg(C.chip).text_color(C.text))
    .on_click(onClick)
    .child(svg(`mods/terminal-acario-bar/${icon}.svg`).size(17));
}

// "2026-11-03 18:45 UTC"
function utcNow() {
  return new Date().toISOString().slice(0, 16).replace("T", " ") + " UTC";
}

export default class TerminalsBar extends View {
  init(_props, cx) {
    // Redraw a few times a minute so the clock never lags by more than a tick.
    this.clock = cx.timer.every(10000, (c) => c.notify());
  }

  render() {
    const t = theme();
    const space = spaces().find((p) => p.active);
    if (!space) return div();
    const all = panes();
    const w = win() ?? {};

    const tab = (c) => {
      const p = lead(all, c.id);
      const where = c.named ? "" : folder(p?.cwd);
      return own(h_flex())
        .id(`tm-${c.id}`)
        .flex_shrink(1)
        .w(200)
        .min_w(0)
        .h_full()
        .pl(5)
        .pr(12)
        .gap(9)
        .items_center()
        .rounded(13)
        .border_1()
        .cursor_pointer()
        .text_size(13)
        .when(c.active, (el) => el.bg(C.tab).border_color(C.tabEdge))
        .when(!c.active, (el) => el.border_color("#00000000").hover((s) => s.bg(C.hover)))
        .on_click(() => run("tab.select", { id: c.id }))
        .on_mouse_down("right", () =>
          openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: c.id, space: space.id } } }),
        )
        .child(tile(t, p))
        .child(
          h_flex()
            .min_w(0)
            .gap(6)
            .truncate()
            .child(div().flex_none().text_color(c.active ? C.text : "#2c2f3e").child(c.name))
            .when(Boolean(where), (el) => el.child(div().truncate().text_color(C.dim).child(where))),
        );
    };

    return h_flex()
      .size_full()
      .gap(8)
      .items_center()
      // With the sidebar hidden the macOS traffic lights sit over the bar: leave room.
      .when(w.platform === "macos" && w.titlebar === "none" && !w.fullscreen && (!find(layout(), "sidebar") || Boolean(find(layout(), "sidebar").hidden)), (el) => el.pl(72))
      .child(
        own(h_flex())
          .id("tm-space")
          .flex_none()
          .min_w(150)
          .h(30)
          .pl(10)
          .pr(12)
          .gap(8)
          .items_center()
          .justify_center()
          .rounded_full()
          .bg(space.machine ? "#1F55A0" : "#009B7C")
          .cursor_pointer()
          .text_size(13)
          .text_color("#ffffff")
          .on_click(() => openOverlay({ mod: "picker", kind: "popup", at: "top", offset: 40, width: 640, height: 0.8 }))
          .child(svg(`mods/workspace-chrome/${space.machine ? "server" : "monitor"}.svg`).size(15))
          .child(div().max_w(160).truncate().text_color("#ffffff").child(space.machine ?? "This computer")),
      )
      .child(
        h_flex()
          .flex_shrink(1)
          .min_w(0)
          .h(36)
          .p(3)
          .gap(3)
          .rounded(16)
          .bg(C.tray)
          .children(space.tabs.map(tab)),
      )
      .child(div().flex_1())
      .child(iconButton("tm-keys", "command", () => run("app.palette")))
      .child(iconButton("tm-new", "plus", () => run("tab.new", { space: space.id })))
      .child(
        h_flex()
          .flex_none()
          .h(36)
          .px(12)
          .gap(8)
          .items_center()
          .rounded(13)
          .border_1()
          .border_color("#00000000")
          .bg(C.tray)
          .text_size(13)
          .text_color(C.text)
          .child(div().flex_none().child("🕒"))
          .child(div().flex_none().child(utcNow())),
      )
      .when(Boolean(w.buttons), (el) =>
        el.child(
          h_flex()
            .flex_none()
            .pl(6)
            .pr(4)
            .gap(8)
            .child(windowButton("tm-min", "win-min", "window.minimize"))
            .child(windowButton("tm-max", w.maximized ? "win-restore" : "win-max", "window.maximize"))
            .child(windowButton("tm-close", "win-close", "window.close")),
        ),
      );
  }
}
