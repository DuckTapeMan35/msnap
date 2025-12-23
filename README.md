# Mango utils

Utilities that interact with **mango IPC (mmsg)** to provide a better experience, instead of manually configuring basic tasks such as screenshots and screencasts.

---

## Project Status

> ⚠️ **Early stage**
>
> Currently, this project does not provide anything particularly special.
> The only functionality that directly interacts with **mango IPC (mmsg)** at the moment is **current window screenshots**.
>
> However, all dependencies are carefully chosen to work well with **mangowc (wlroots)**.
> Full **mmsg integration** is intentionally deferred until mangowc’s **new IPC implementation** becomes available.
>
> The current focus is:
>
> * Stable CLI tools
> * Clean UX
> * A pathway for the GUI implementation

---

## Tools

### `mcast`

Screen recording utility for mangowc.

### `mshot`

Screenshot utility with support for region, window, clipboard, and annotation workflows.

---

## Dependencies

### `mcast`

Required:

* `wf-recorder`
* `slurp`
* `notify-send`

### `mshot`

Required:

* `grim`
* `slurp`
* `wl-copy`
* `notify-send`

Optional:

* `satty` — for screenshot annotation

---

## Installation
```sh
curl -fsSL https://raw.githubusercontent.com/atheeq-rhxn/mango-utils/main/install.sh | sh
```

## Usage

### `mcast`

Record the entire screen:

```sh
mcast
```

Select a region:

```sh
mcast -r
```

Custom output location and filename:

```sh
mcast -o ~/Videos -f mycast.mp4
```

---

### `mshot`

Fullscreen screenshot:

```sh
mshot
```

Select a region:

```sh
mshot -r
```

Capture a window:

```sh
mshot -w
```

Include pointer:

```sh
mshot -p
```

Annotate after capture:

```sh
mshot -a
```

Disable clipboard copy:

```sh
mshot --no-copy
```

---

## Development

* CLI tools are implemented using **[bashly](https://bashly.dev/)**
* Each tool lives in its own directory

### Build

Inside a tool’s directory:

```sh
bashly generate
```
