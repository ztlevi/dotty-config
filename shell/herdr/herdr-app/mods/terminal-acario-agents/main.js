// Agents in grouped or priority views; parents take their most urgent sub-agent's place.
// A viewed done agent stays in Done until left.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { hc, notify, playSound, agents, terminals, panes, focused, spaces, machines, exec, run, theme, shared, setShared, setAgentOrder, nextCommand, openOverlay, closeOverlay, props, window, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// To the rail (on macOS wide enough for the traffic lights), or back to the width it had.
function toggleSidebar() {
  const width = find(layout(), "sidebar")?.size?.px;
  if (!narrow()) setShared("sidebar.width", width);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !narrow());
  run("layout.resize", { id: "sidebar", px: narrow() ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

// ---- Claude background sessions (what `claude agents` lists) ----------------
// Read with `claude agents --json --all` plus each job's state.json (its
// one-line summary), on this computer and on every connected machine.


// Each machine gets its own color, kept in shared("machine.colors") so every mod agrees:
// this computer is always green; remote machines take the next color from the palette
// in the order they are first seen (alphabetical when several appear at once), and
// wrap back to the first (blue) when the palette runs out.
const MACHINE_PALETTE = ["#1F55A0", "#6B4FA0", "#B5651D", "#0E7C86", "#A63D40", "#7A6A1F", "#9C3D7A"];
function machineColor(name) {
  if (!name) return "#009B7C";
  const map = shared("machine.colors") ?? {};
  if (map[name] === undefined) {
    const missing = [...new Set([...machines().map((m) => m.name).filter(Boolean), name])].filter((n) => map[n] === undefined).sort();
    const next = { ...map };
    let i = Object.keys(map).length;
    for (const n of missing) next[n] = i++;
    setShared("machine.colors", next);
    return MACHINE_PALETTE[next[name] % MACHINE_PALETTE.length];
  }
  return MACHINE_PALETTE[map[name] % MACHINE_PALETTE.length];
}
// A darker shade of #rrggbb, for hover.
const darker = (hex, k = 0.82) => "#" + [1, 3, 5].map((i) => Math.round(parseInt(hex.slice(i, i + 2), 16) * k).toString(16).padStart(2, "0")).join("");
const machineOf = (address) => (address?.includes("/") ? address.split("/")[0] : null);
const norm = (s) => clean(s).toLowerCase();
const CLAUDE = { key: "claude", name: "Claude Code", icon: "icons/claude.svg", tint: false, tile: null, color: null, shell: false, agent: true };

// First [...] in `text`: a login shell may print banners around the JSON.
function jsonArray(text) {
  const a = text.indexOf("[");
  const b = text.lastIndexOf("]");
  return a >= 0 && b > a ? JSON.parse(text.slice(a, b + 1)) : [];
}

async function fetchSessions(on) {
  const opts = on ? { on } : {};
  const r = await exec("sh", ["-lc", "claude agents --json --all"], opts);
  if (r.code !== 0) return [];
  const jobs = jsonArray(r.stdout).filter((j) => j.kind === "background");
  // One call for every job's summary, instead of one read per job.
  const d = await exec(
    "sh",
    ["-c", 'for f in "$HOME"/.claude/jobs/*/state.json; do [ -f "$f" ] || continue; printf "%s\t" "$(basename "$(dirname "$f")")"; tr "\n" " " < "$f"; echo; done'],
    opts,
  ).catch(() => ({ code: 1, stdout: "" }));
  const detail = new Map();
  for (const line of d.stdout.split("\n")) {
    const tab = line.indexOf("\t");
    if (tab < 0) continue;
    try {
      const j = JSON.parse(line.slice(tab + 1));
      detail.set(line.slice(0, tab), { detail: j.detail, updatedAt: j.updatedAt ? Date.parse(j.updatedAt) : 0 });
    } catch {}
  }
  return jobs.map((j) => ({ ...j, machine: on ?? null, summary: detail.get(j.id)?.detail ?? "", updatedAt: detail.get(j.id)?.updatedAt || j.startedAt }));
}

// claude's state word -> herdr's status word. Completed sessions are idle.
function sessionStatus(j) {
  const w = `${j.state ?? ""} ${j.status ?? ""}`.toLowerCase();
  if (/block|await|input|permission|needs/.test(w)) return "blocked";
  if (/work|busy|running/.test(w)) return "working";
  return "idle";
}

function lead(tab, all = panes()) {
  const mine = all.filter(p => p.tab === tab.id && p.terminal);
  return mine.find(p => p.program?.agent) ?? mine.find(p => p.focused) ?? mine[0];
}

function title(tab, l) {
  const prog = l?.program?.name;
  const live = clean(l?.title);
  const telling = live && live !== prog && !/^[~/]|^[A-Za-z]:\\/.test(live) && !live.includes("@") && live.toLowerCase() !== l?.program?.key;
  return (tab.name === prog || !tab.named) && telling ? live : tab.name;
}
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
// A sub-agent without a pane isn't in agents(): its raw word, error counting as
// blocked. It's never done: it reports to its parent, and the parent's done is the news.
const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};
const SORTS = [
  { id: "priority", label: "Priority", icon: "clock" },
  { id: "grouped", label: "Grouped by space", icon: "layers" },
];
const sortOf = () => SORTS.find((s) => s.id === shared("agents.sort")) ?? SORTS[0];
const SECTION = { 4: "Needs you", 3: "Done", 2: "Working", 1: "Completed" };
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working" };

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

// The agent's icon from the app's program table: a one-color glyph or a picture.
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

export default class Agents extends View {
  init(_props, cx) {
    // The menu and the rename dialog are popups of this same mod: no polling for them.
    if (props()?.renameSession) return this.initRename(cx);
    if (props()?.sortMenu || props()?.sessionMenu) return;
    this.folded = new Set();
    // Each agent's last state and when it changed (ms), kept across restarts.
    this.changed = JSON.parse(localStorage.getItem("changed") ?? "{}");
    this.pendingPins = JSON.parse(localStorage.getItem("pins") ?? "[]");
    if (!this.pendingPins.length) localStorage.removeItem("pins");
    this.migratingPins = new Set();
    cx.timer.every(30000, (cx) => cx.notify());
    this.sessions = [];
    this.order = [];
    // cmd-] / cmd-[ (keys.json: "terminal-acario-agents.next" / ".prev").
    cx.spawn(async (c) => {
      for (;;) {
        const cmd = await nextCommand();
        if (cmd === "next" || cmd === "prev") this.step(cmd === "next" ? 1 : -1);
        // A toast's click: "open:<session address>".
        else if (cmd.startsWith("open:")) {
          const row = (this.rows ?? []).find((r) => r.address === cmd.slice(5));
          if (row) this.open(row);
        }
        c.notify();
      }
    });
    this.loadSessions(cx);
    cx.timer.every(5000, (c) => this.loadSessions(c));
  }

  async loadSessions(cx) {
    if (this.loading) return;
    this.loading = true;
    try {
      const on = [null, ...machines().filter((m) => m.name && m.layout === "ready").map((m) => m.name)];
      const got = await Promise.all(on.map((m) => fetchSessions(m).catch(() => [])));
      const next = got.flat();
      this.alertOn(next);
      if (JSON.stringify(next) !== JSON.stringify(this.sessions)) {
        this.sessions = next;
        cx.notify();
      }
    } finally {
      this.loading = false;
    }
  }

  // herdr plays its done/blocked sounds when you are NOT looking at the agent. Play them
  // here too when you are, so a finish or a block is never silent. Agents you aren't
  // looking at are left to herdr, or you would hear every alert twice.
  soundOn(list) {
    const before = this.lastSeen;
    const next = new Map();
    const looking = Boolean(window()?.active);
    for (const a of list) {
      next.set(a.address, a.status);
      const was = before?.get(a.address);
      if (!before || was === undefined || was === a.status) continue;
      if (!(looking && a.focused)) continue;
      if (a.status === "blocked" || a.status === "error") playSound("blocked");
      else if (a.status === "idle" && was === "working") playSound("done");
    }
    this.lastSeen = next;
  }

  // herdr alerts for the agents it tracks; do the same for sessions it can't see:
  // a sound and a toast when one finishes or needs you, on any machine. A machine's
  // first read only records where things stand.
  alertOn(next) {
    const before = this.lastStatus ?? new Map();
    const known = this.lastMachines ?? new Set();
    const now = new Map();
    const machines = new Set();
    const tracked = agents();
    for (const j of next) {
      const key = `${j.machine ?? ""}|${j.id}`;
      const st = sessionStatus(j);
      now.set(key, st);
      machines.add(j.machine ?? "");
      const prev = before.get(key);
      if (!known.has(j.machine ?? "") || prev === st) continue;
      // A session can start, stop to ask something, and be there already blocked at the
      // next look: one we hadn't seen alerts too when it is waiting on us, or just finished.
      const fresh = prev === undefined;
      const recent = Date.now() - (j.updatedAt || 0) < 120000;
      const kind = st === "blocked" ? "blocked" : st === "idle" && (fresh ? recent : prev === "working") ? "done" : null;
      if (!kind) continue;
      // Already told by herdr (it tracks the terminal) or being looked at: stay quiet.
      const mine = tracked.find((x) => machineOf(x.address) === j.machine && norm(x.title) === norm(j.name));
      const pane = panes().find((p) => p.terminal && machineOf(p.terminal) === j.machine && norm(p.title) === norm(j.name));
      if (mine || (pane && focused()?.pane === pane.pane)) continue;
      playSound(kind);
      notify({
        title: j.name || j.id,
        body: `${kind === "blocked" ? "Needs you" : "Finished"}${j.machine ? ` · ${j.machine}` : ""}${j.summary ? ` — ${clean(j.summary)}` : ""}`,
        level: kind === "blocked" ? "warning" : "success",
        icon: kind === "blocked" ? "icons/acario-alert.svg" : "icons/acario-done.svg",
        timeout: 10000,
        action: { name: "terminal-acario-agents.open:" + `cs:${j.machine ?? ""}:${j.id}` },
      });
    }
    this.lastStatus = now;
    this.lastMachines = machines;
  }

  // The terminal running `claude agents` on a machine. Its title turns into a
  // session's name while one is open in it, so ask the core what it is running.
  async findAgentsView(machine) {
    const cands = panes().filter((p) => p.terminal && p.program?.key === "claude" && machineOf(p.terminal) === machine);
    for (const p of cands) {
      try {
        const r = await hc(["get", p.terminal, "--json"]);
        const argv = JSON.parse(r.stdout).foreground?.argv ?? [];
        if (/(^|\/)claude$/.test(argv[0] ?? "") && argv.at(-1) === "agents") return p;
      } catch {}
    }
    return null;
  }

  // A session row: go to the live terminal showing it, else to the tab running
  // `claude agents`, else attach in a new tab on the session's machine.
  async openSession(a) {
    if (a.pane) return run("pane.focus", { pane: a.pane });
    const view = await this.findAgentsView(a.machine);
    if (view) return run("pane.focus", { pane: view.pane });
    const space = spaces().find((s) => (s.machine ?? null) === a.machine);
    const argv = ["claude", "attach", a.id];
    if (space) run("tab.new", { space: space.id, name: a.name, folder: a.cwd, argv });
    else run("space.new", { name: a.name, folder: a.cwd, argv, machine: a.machine ?? "" });
  }

  // Go to the next/previous agent in the order the list shows, wrapping round.
  // Rows open in a terminal take part, and so do sessions still working or waiting;
  // finished ones don't, or stepping would spawn a tab for each.
  step(dir) {
    const rows = this.order;
    if (!rows.length) return;
    // Where we are: the row we stepped to last (while it's still the focus or
    // shares it, e.g. two sessions living in one agents view), else the focused one.
    const here = focused()?.pane;
    let at = rows.findIndex((a) => a.address === this.cursor);
    if (at < 0 || (rows[at].pane && rows[at].pane !== here)) at = rows.findIndex((a) => a.focused || (a.pane && a.pane === here));
    const to = at < 0 ? (dir > 0 ? 0 : rows.length - 1) : (at + dir + rows.length) % rows.length;
    this.cursor = rows[to].address;
    this.open(rows[to]);
  }


  // ---- Right-click on a session: rename, stop, delete ------------------------
  // They act on the session's machine (`on`), where `claude` and its job files live.

  // Rename = write the name into the job's state.json with nameSource "user"; `claude
  // agents` reads it from there. Written atomically, by python on the session's machine.
  async renameJob(s, name) {
    const py = 'import json,os,sys;p=os.path.expanduser("~/.claude/jobs/%s/state.json"%sys.argv[1]);d=json.load(open(p));d["name"]=sys.argv[2];d["nameSource"]="user";t=p+".tmp";json.dump(d,open(t,"w"),indent=2);os.replace(t,p)';
    return exec("sh", ["-lc", 'python3 -c "$1" "$2" "$3"', "sh", py, s.id, name], s.machine ? { on: s.machine } : {});
  }

  async claudeCmd(s, verb) {
    return exec("sh", ["-lc", `claude ${verb} ${s.id}`], s.machine ? { on: s.machine } : {});
  }

  async runAction(s, label, job) {
    try {
      const r = await job();
      if (r.code !== 0) throw new Error((r.stderr || r.stdout || `exit ${r.code}`).trim().split("\n")[0]);
    } catch (e) {
      notify({ title: `${label} failed`, body: `${s.name}: ${e.message ?? e}`, level: "error", icon: "icons/acario-error.svg" });
    }
  }

  sessionMenu(t) {
    const s = props().sessionMenu;
    const close = () => closeOverlay(props().overlay);
    const item = (id, text, onClick, color = t.foreground) =>
      h_flex().id(id).h(31).px(8).rounded(7).items_center().text_color(color).hover((el) => el.bg(t.hover)).on_click(onClick).child(text);
    const head = div().px(8).pt(4).pb(6).text_size(11).text_color(t.dim).truncate().child(s.name);
    if (this.confirming) {
      return v_flex().w_full().p(5).bg(t.popover).text_size(12.8)
        .child(head)
        .child(div().px(8).pb(8).text_size(11.5).text_color(t.muted).child("Delete this session and its worktree? This can't be undone."))
        .child(item("sm-yes", "Delete", () => { close(); this.runAction(s, "Delete", () => this.claudeCmd(s, "rm")); }, t.blocked))
        .child(item("sm-no", "Cancel", close));
    }
    return v_flex().w_full().p(5).bg(t.popover).text_size(12.8)
      .child(head)
      .child(item("sm-rename", "Rename…", () => {
        close();
        openOverlay({ mod: "terminal-acario-agents", kind: "dialog", width: 380, height: 190, props: { renameSession: s } });
      }))
      .when(s.status !== "idle", (el) => el.child(item("sm-stop", "Stop", () => { close(); this.runAction(s, "Stop", () => this.claudeCmd(s, "stop")); })))
      .child(item("sm-del", "Delete…", (_e, cx) => { this.confirming = true; cx.notify(); }, t.blocked));
  }

  initRename(cx) {
    const s = props().renameSession;
    this.text = s.name;
    this.input = InputState.new({ value: this.text });
    this.input.set_selected_range({ start: 0, end: this.text.length });
    this.input.on("change", (_e, c) => { this.text = this.input.value(); c.notify(); });
    this.input.on("submit", () => this.saveRename());
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
  }

  saveRename() {
    const s = props().renameSession;
    const name = (this.text ?? "").trim();
    closeOverlay(props().overlay);
    if (name && name !== s.name) this.runAction(s, "Rename", () => this.renameJob(s, name));
  }

  renameDialog(t) {
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8)
      .border_1().border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .hover((el) => el.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("rename-session").track_focus(this.handle)
      .on_key_down((e, cx) => { if (e.key === "escape") { closeOverlay(props().overlay); cx.stop_propagation(); } })
      .w_full().min_h(0).p(18).bg(t.popover).text_color(t.foreground)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child("Rename session")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().pt(16).pb(7).text_size(11.5).text_color(t.dim).child("Name"))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(h_flex().pt(20).gap(8).justify_end()
        .child(button("rn-cancel", "Cancel", false, () => closeOverlay(props().overlay)))
        .child(button("rn-save", "Save", true, () => this.saveRename())));
  }

  // The `claude agents` view of a machine: its terminal if one is running, else a new tab.
  async openView(machine) {
    const view = await this.findAgentsView(machine);
    if (view) return run("pane.focus", { pane: view.pane });
    const space = spaces().find((s) => (s.machine ?? null) === machine);
    const argv = ["claude", "agents"];
    if (space) run("tab.new", { space: space.id, name: "claude agents", argv });
    else run("space.new", { name: "claude agents", argv, machine: machine ?? "" });
  }

  // A session under its `claude agents` parent: tree lines, name, summary below.
  sessionRow(t, k, last) {
    const h = k.summary ? 40 : 28;
    const line = "#a9acbb";
    const idle = k.status === "idle" && !k.focused;
    const when = this.since(k);
    return h_flex()
      .id(`ks-${k.address}`)
      .pl(22)
      .pr(8)
      .h(h)
      .flex_none()
      .gap(7)
      .items_center()
      .rounded(8)
      .when(k.focused, (el) => el.bg(t.selected))
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click(() => this.open(k))
      .on_mouse_down("right", () =>
        openOverlay({ mod: "terminal-acario-agents", kind: "popup", width: 210, height: 150, props: { sessionMenu: { id: k.id, machine: k.machine, name: k.name, status: k.status } } }),
      )
      .child(
        div().relative().flex_none().w(14).h(h)
          .child(div().absolute().left(2).top(0).w(1.5).h(last ? h / 2 : h).bg(line))
          .child(div().absolute().left(2).top(h / 2 - 0.75).w(11).h(1.5).bg(line)),
      )
      .child(
        v_flex().flex_1().min_w(0).gap(1)
          .child(div().min_w(0).truncate().text_color(idle ? t.muted : t.foreground).child(k.name))
          .when(Boolean(k.summary), (el) => el.child(div().min_w(0).truncate().text_size(11.5).text_color(t.dim).child(k.summary))),
      )
      .when(Boolean(when), (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(duration(Date.now() - when))))
      .child(this.status(t, k, false));
  }

  open(a) {
    if (a.group) return this.openView(a.machine);
    if (a.session) return this.openSession(a);
    run("pane.focus", { pane: a.pane });
  }

  // Stamps agents whose state changed. Done and idle count as one: looking at a
  // finished agent turns done into idle, and looking isn't the agent doing anything.
  track(list, now) {
    let dirty = false;
    for (const a of list) {
      const s = a.status === "done" ? "idle" : a.status;
      if (this.changed[a.address]?.s === s) continue;
      this.changed[a.address] = { s, at: a.at ?? now };
      dirty = true;
    }
    if (!dirty) return;
    // Gone and old: the list alone is empty right after a start.
    const listed = new Set(list.map((a) => a.address));
    for (const [k, c] of Object.entries(this.changed)) if (!listed.has(k) && now - c.at > 30 * 86400000) delete this.changed[k];
    localStorage.setItem("changed", JSON.stringify(this.changed));
  }

  // Keep offline pins until their terminal returns, and keep each pending until
  // core echoes the label so a failed write doesn't erase the old pin.
  migratePins(all) {
    const listed = new Map(all.filter((t) => t.state === "live").map((t) => [t.address, t]));
    const pending = this.pendingPins.filter((address) => {
      const terminal = listed.get(address);
      if (!terminal) return true;
      if (terminal.labels?.["herdr.pinned"]) return false;
      if (!this.migratingPins.has(address)) {
        this.migratingPins.add(address);
        run("terminal.pin", { terminal: address, pinned: true });
      }
      return true;
    });
    if (pending.length === this.pendingPins.length) return;
    this.pendingPins = pending;
    if (pending.length) localStorage.setItem("pins", JSON.stringify(pending));
    else localStorage.removeItem("pins");
  }

  since(a) {
    return this.changed[a.address]?.at ?? 0;
  }

  // Looking at a done agent makes it idle; it stays with Done until you leave
  // it rather than drop away under you. Any other change moves it at once.
  hold(list) {
    const cur = list.find((a) => a.focused);
    const same = cur && cur.address === this.held?.address;
    // Arriving, or any change but done turning idle, sets what it was.
    if (!same || cur.status !== "idle") this.held = cur ? { address: cur.address, rank: RANK[cur.status] ?? 0 } : null;
  }

  rank(a) {
    const sawDone = a.address === this.held?.address && this.held.rank === RANK.done && a.status === "idle";
    return sawDone ? RANK.done : RANK[a.status] ?? 0;
  }

  sortMenu(t) {
    const on = sortOf().id;
    return v_flex()
      .w_full()
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .child(div().px(8).pt(4).pb(6).text_size(11).text_color(t.dim).child("Sort agents"))
      .children(SORTS.map((s) => h_flex()
        .id(`sort-${s.id}`)
        .h(31)
        .px(8)
        .gap(9)
        .rounded(7)
        .items_center()
        .text_color(t.foreground)
        .hover((el) => el.bg(t.hover))
        .on_click(() => {
          setShared("agents.sort", s.id);
          closeOverlay(props().overlay);
        })
        .child(svg(`mods/workspace-chrome/${s.icon}.svg`).size(14).flex_none().text_color(t.muted))
        .child(div().flex_1().child(s.label))
        .when(s.id === on, (el) => el.child(svg("mods/workspace-chrome/check.svg").size(14).flex_none().text_color(t.foreground)))));
  }

  peek(addr) {
    run("terminal.peek", { terminal: addr });
  }

  // Live sub-agents of `addr`, depth first, each with the tree lines in front of it.
  tree(all, addr, lead = []) {
    const kids = all.filter((k) => k.parent === addr && k.state === "live");
    return kids.flatMap((k, i) => {
      const last = i === kids.length - 1;
      return [
        { t: k, lines: [...lead, last ? "└" : "├"] },
        ...this.tree(all, k.address, [...lead, last ? "" : "│"]),
      ];
    });
  }

  subRow(t, s, shown, compact) {
    const k = s.t;
    const st = kidStatus(k, this.listed);
    const pic = icon(k.program, 14, t.foreground);
    const on = k.address === shown;
    return h_flex()
      .id(`sub-${k.address}`)
      .pl(39)
      .pr(8)
      .rounded(8)
      .h(26)
      .flex_none()
      .gap(0)
      .items_center()
      .text_size(12.5)
      .when(on, (el) => el.bg(t.raised))
      .hover((s) => s.bg(t.hover))
      .on_click(() => this.peek(k.address))
      .children(s.lines.map(l => div().self_start().mt(-4).w(9).h(17).mr(4).flex_none()
        .when(Boolean(l), el => el.border_l(1.5).border_color(t.input))
        .when(l === "└" || l === "├", el => el.border_b(1.5).rounded_bl(6))))
      .when(Boolean(pic), el => el.child(div().mr(8).child(pic)))
      .child(div().flex_1().truncate().text_color(on ? t.foreground : t.muted).child(k.name || k.template || k.program?.name || k.address))
      .child(this.status(t, { status: st }, compact));
  }

  // compact: a ! for blocked where a header already says "Needs you".
  status(t, a, compact = false) {
    const color = t[a.status] ?? t.dim;
    if (a.status === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).mx(1).flex_none().text_color(t.working).spin(900);
    if (a.status === "blocked" && compact) return div().size(14).flex_none().rounded(4).bg(t.blocked + "26").text_size(10.5).font_bold().text_color(t.blocked).flex().items_center().justify_center().child("!");
    if (a.status === "blocked") return div().flex_none().px(6).h(18).rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).flex().items_center().child("Needs you");
    // Idle: a ring; done: a dot.
    if (a.status === "idle") return div().size(7).mx(3).flex_none().rounded(4).border(1.5).border_color(t.idle ?? t.dim);
    return div().size(7).mx(3).flex_none().rounded(4).bg(a.status === "done" ? color : t.dim + "00");
  }

  render(cx) {
    const t = theme();
    if (props()?.sortMenu) return this.sortMenu(t);
    if (props()?.sessionMenu) return this.sessionMenu(t);
    if (props()?.renameSession) return this.renameDialog(t);
    const collapsed = narrow();
    const sort = sortOf();
    const live = panes();
    // A session already open in a terminal is that terminal's row: the terminal
    // title is the session name. Match on machine + name.
    const shownBy = new Map(live.filter((p) => p.terminal && p.program?.key === "claude" && norm(p.title) !== "claude agents").map((p) => [`${machineOf(p.terminal)}|${norm(p.title)}`, p]));
    const taken = new Set();
    const sessions = (this.sessions ?? []).map((j) => {
      const p = shownBy.get(`${j.machine}|${norm(j.name)}`);
      if (p) taken.add(p.pane);
      return {
        session: true,
        id: j.id,
        name: j.name || j.id,
        summary: clean(j.summary),
        cwd: j.cwd,
        machine: j.machine,
        address: `cs:${j.machine ?? ""}:${j.id}`,
        pane: p?.pane ?? null,
        terminal: p?.terminal ?? null,
        focused: Boolean(p?.focused),
        pinned: false,
        status: sessionStatus(j),
        app: "claude-code",
        program: CLAUDE,
        title: j.name,
        space: `cs-${j.machine ?? ""}`,
        space_name: j.machine ?? "This computer",
        tab: p?.tab ?? null,
        at: j.updatedAt || undefined,
        seq: 0,
      };
    });
    // Sessions belong to the `claude agents` view of their machine: one parent row
    // per machine, its sessions nested underneath like sub-agents.
    const byMachine = new Map();
    for (const k of sessions) {
      const key = k.machine ?? "";
      if (!byMachine.has(key)) byMachine.set(key, []);
      byMachine.get(key).push(k);
    }
    const parents = [...byMachine].map(([key, kids]) => {
      kids.sort((x, y) => (RANK[y.status] ?? 0) - (RANK[x.status] ?? 0) || (y.at ?? 0) - (x.at ?? 0));
      const machine = key || null;
      return {
        group: true,
        kids,
        name: "claude agents",
        machine,
        address: `cg:${key}`,
        pane: null,
        focused: false,
        pinned: false,
        status: kids.reduce((top, k) => ((RANK[k.status] ?? 0) > (RANK[top] ?? 0) ? k.status : top), "idle"),
        app: "claude-code",
        program: CLAUDE,
        title: "claude agents",
        space: `cs-${key}`,
        space_name: machine ?? "This computer",
        tab: null,
        at: Math.max(0, ...kids.map((k) => k.at ?? 0)) || undefined,
        seq: 0,
      };
    });
    const virt = (a) => a.session || a.group;
    const plain = agents().filter((a) => !taken.has(a.pane));
    let list = [...plain, ...parents];
    if (sort.id !== "priority") {
      const order = spaces().map((s) => s.id);
      const at = (a) => (order.includes(a.space) ? order.indexOf(a.space) : order.length + (a.machine ? 1 : 0));
      list = list.map((a, i) => [a, i]).sort((x, y) => at(x[0]) - at(y[0]) || x[1] - y[1]).map(([a]) => a);
    }
    this.listed = new Map(list.map((a) => [a.address, a.status]));
    const all = terminals();
    this.migratePins(all);
    const shown = focused()?.agent;
    const now = Date.now();
    this.track([...list, ...sessions], now);
    this.soundOn(plain);
    this.hold(list);
    const byPriority = sort.id === "priority";
    const urgency = new Map(list.map((a) => [a.address, Math.max(this.rank(a), ...this.tree(all, a.address).map((s) => RANK[kidStatus(s.t, this.listed)] ?? 0))]));
    const rankOf = (a) => urgency.get(a.address);
    if (byPriority) list = [...list].sort((x, y) => rankOf(y) - rankOf(x) || this.since(y) - this.since(x) || y.seq - x.seq);
    const pinned = list.filter((a) => a.pinned);
    const rest = list.filter((a) => !a.pinned);
    list = [...pinned, ...rest];
    this.rows = [...plain, ...sessions];
    this.order = list.flatMap((a) => (a.group ? a.kids : [a])).filter((a) => a.pane || (a.session && a.status !== "idle"));
    setAgentOrder(list.filter((a) => !virt(a)).map((a) => a.address));

    const withKids = (a, i) => {
      const subs = collapsed ? [] : a.group ? a.kids.map((k, n) => ({ t: k, last: n === a.kids.length - 1 })) : this.tree(all, a.address);
      const r = row(a, i, subs);
      if (this.folded.has(a.address)) return [r];
      return [r, ...subs.map((s) => (a.group ? this.sessionRow(t, s.t, s.last) : this.subRow(t, s, shown, byPriority)))];
    };

    // The fold chevron; folded, the count too, colored by the most urgent one.
    const fold = (a, subs) => {
      const sts = subs.map((s) => kidStatus(s.t, this.listed));
      const top = sts.reduce((m, s) => ((RANK[s] ?? 0) > (RANK[m] ?? 0) ? s : m), null);
      const open = !this.folded.has(a.address);
      return div()
        .id(`fold-${a.address}`)
        .h(18)
        .px(3)
        .gap(3)
        .flex()
        .items_center()
        .rounded(4)
        .text_size(11)
        .text_color(open ? t.dim : (t[top] ?? t.dim))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          open ? this.folded.add(a.address) : this.folded.delete(a.address);
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(11).flex_none())
        .when(!open, (el) => el.child(String(subs.length)));
    };

    // A row reads "space \u00b7 detail": the detail is a tab someone named or the
    // agent's own title, never an automatic tab number unless two rows would
    // otherwise read the same.
    const tabs = spaces().flatMap(s => s.tabs);
    const label = (a) => {
      const tab = tabs.find(tab => tab.id === a.tab);
      return tab ? title(tab, lead(tab)) : a.title || a.program?.name || "";
    };
    const detail = new Map(list.map(a => [a.address, /^\d+$/.test(label(a)) ? null : label(a)]));
    const seen = {};
    for (const a of list) { const k = `${a.space_name}\u0000${detail.get(a.address) ?? ""}`; seen[k] = (seen[k] ?? 0) + 1; }
    for (const a of list) {
      if (detail.get(a.address) == null && seen[`${a.space_name}\u0000`] > 1) detail.set(a.address, label(a));
    }

    const row = (a, i, subs = []) => {
      const pic = icon(a.program, 16, t.foreground);
      const more = a.group ? null : detail.get(a.address);
      // An agent on another machine (`vps/t7`) says which.
      const machine = a.session || a.group ? a.machine : a.address.includes("/") ? a.address.split("/")[0] : null;
      if (collapsed) {
        return h_flex()
          .id(`ag-${a.address}`)
          .h(26)
          .px(8)
          .flex_none()
          .items_center()
          .gap(4)
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.open(a))
          .child(div().flex_1().min_w(0).whitespace_nowrap().text_right().text_color(t.muted).child(String(i + 1)))
          .child(h_flex().w(14).flex_none().items_center().justify_center().child(this.status(t, a, true)));
      }
      const when = this.since(a);
      const idle = a.status === "idle" && !a.focused;
      const isPinned = a.pinned;
      const pin = div()
        .id(`pin-${a.address}`)
        .flex_none()
        .p(2)
        .rounded(4)
        .text_color(t.dim)
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip(isPinned ? "Unpin" : "Pin to the top")
        .on_click((_e, cx) => {
          cx.stop_propagation();
          run("terminal.pin", { terminal: a.address, pinned: !isPinned });
          // The row moves away from under the pointer, and no hover-out comes.
          this.hovered = null;
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${isPinned ? "pin-off" : "pin"}.svg`).size(13));
      // Under a space header the space goes without saying; an automatic tab number says nothing.
      // Without a space header above (priority, pinned) the row names its space.
      const full = byPriority || isPinned;
      const name = a.group ? "claude agents" : full ? a.space_name || label(a) : more ?? (/^\d+$/.test(label(a)) ? a.program?.name || label(a) : label(a));
      return h_flex()
        .id(`ag-${a.address}`)
        .px(8)
        .h(a.session && a.summary ? 44 : 30)
        .flex_none()
        .rounded(8)
        .items_center()
        .gap(9)
        .when(a.focused, (el) => el.bg(t.selected))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = a.address;
          else if (this.hovered === a.address) this.hovered = null;
          cx.notify();
        })
        .on_click(() => this.open(a))
        .when(Boolean(pic), el => el.child(div().id(`agent-fold-${a.address}`)
          .when(subs.length > 0, el => el.on_click((_e, cx) => {
            cx.stop_propagation();
            this.folded.has(a.address) ? this.folded.delete(a.address) : this.folded.add(a.address);
            cx.notify();
          })).child(pic)))
        .child(a.session
          ? v_flex().flex_1().min_w(0).gap(1)
              .child(div().min_w(0).truncate().text_color(idle ? t.muted : t.foreground).child(a.name))
              .when(Boolean(a.summary), el => el.child(div().min_w(0).truncate().text_size(11.5).text_color(t.dim).child(a.summary)))
          : h_flex().flex_1().min_w(0).gap(5).items_center()
          .child(div().min_w(0).max_w(full && more ? 120 : 200).truncate().text_color(idle ? t.muted : t.foreground).child(name))
          .when(full && Boolean(more), el => el.child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(`\u00b7 ${more}`))))
        // Where it runs, as a pill like the host pill's: green with a monitor for this
        // computer, blue with the machine's name for a remote one. White ink on both.
        .child(h_flex().flex_none().h(17).px(machine ? 6 : 5).rounded_full().items_center().justify_center().bg(machineColor(machine)).text_color("#ffffff")
          .child(machine
            ? div().text_size(10.5).child(machine)
            : svg("mods/workspace-chrome/monitor.svg").size(11).flex_none()))
        .when(subs.length > 0, el => el.child(fold(a, subs)))
        .when(this.hovered === a.address && !virt(a), el => el.child(pin))
        .when((this.hovered !== a.address || virt(a)) && Boolean(when), el => el.child(div().flex_none().text_size(11).text_color(t.dim).child(duration(now - when))))
        .child(this.status(t, a, byPriority && !isPinned));
    };

    // Groups in list order: spaces (grouped) or priority sections. Agents of a
    // space are next to each other in agents(), so neighbours make a group.
    const groups = pinned.length ? [{ id: "pinned", label: "Pinned", status: null, members: pinned }] : [];
    for (const a of rest) {
      const r = rankOf(a) || RANK.idle;
      const id = byPriority ? `sec-${r}` : `sp-${a.space}`;
      if (groups.at(-1)?.id === id) groups.at(-1).members.push(a);
      else groups.push({ id, label: byPriority ? SECTION[r] : a.space_name || "", status: byPriority ? SECTION_STATUS[r] : null, members: [a] });
    }

    // A group's header; it folds the group. Folded, it says how many and the most urgent state.
    const header = (g) => {
      const open = !this.folded.has(g.id);
      const top = g.members.reduce((m, a) => ((RANK[a.status] ?? 0) > (RANK[m] ?? 0) ? a.status : m), null);
      return h_flex()
        .id(g.id)
        .px(8)
        .pt(8)
        .h(30)
        .flex_none()
        .gap(6)
        .items_center()
        .text_size(11)
        .font_medium()
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          open ? this.folded.add(g.id) : this.folded.delete(g.id);
          cx.notify();
        })
        .child(div().truncate().text_color(t[g.status] ?? t.dim).child(g.label))
        .when(byPriority || !open, (el) => el.child(div().text_color(t.dim).child(String(g.members.length))))
        .child(div().flex_1())
        .when(!open, (el) => el
          .when(!byPriority && top && top !== "idle", (el) => el.child(this.status(t, { status: top }, true)))
          .child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none().text_color(t.dim)));
    };
    const rows = collapsed
      ? list.flatMap(withKids)
      : groups.flatMap((g) => [header(g), ...(this.folded.has(g.id) ? [] : g.members.flatMap(withKids))]);

    return v_flex()
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .when(!collapsed, (el) =>
        el.child(
          h_flex()
            .px(16)
            .h(41)
            .pt(14)
            .pb(5)
            .flex_none()
            .items_center()
            .justify_between()
            .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Agents"))
            .child(
              div()
                .id("ag-sort")
                .text_size(11)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(() => openOverlay({ mod: "terminal-acario-agents", kind: "popup", width: 200, height: 140, props: { sortMenu: true } }))
                .tooltip(`Sort agents: ${sort.label}`)
                .child(svg(`mods/workspace-chrome/${sort.icon}.svg`).size(14)),
            ),
        ),
      )
      .when(list.length === 0 && !collapsed, (el) =>
        el.child(div().px(12).text_size(12).text_color(t.dim).child("No agent status yet. Agents show up here when they report their status. Older versions and agents inside tmux may not.")),
      )
      .child(v_flex().id("ag-list").flex_1().min_h(0).px(collapsed ? 0 : 8).overflow_y_scrollbar().mode("always").children(rows))
      .when(collapsed, (el) =>
        el.child(
          h_flex()
            .h(28)
            .items_center()
            .justify_center()
            .child(
              div()
                .id("collapse")
                .text_size(13)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(toggleSidebar)
                .child("»"),
            ),
        ),
      );
  }
}
