local function executable(name)
    return vim.fn.executable(name) == 1
end

local function is_wsl()
    local path = "/proc/sys/kernel/osrelease"
    if vim.fn.filereadable(path) == 0 then
        return false
    end

    local release = table.concat(vim.fn.readfile(path), "\n")
    return release:lower():find("microsoft", 1, true) ~= nil
end

local function has_native_clipboard()
    if vim.env.WAYLAND_DISPLAY and vim.env.WAYLAND_DISPLAY ~= ""
        and executable("wl-copy") and executable("wl-paste") then
        return true
    end

    return vim.env.DISPLAY ~= nil and vim.env.DISPLAY ~= ""
        and (executable("xclip") or executable("xsel"))
end

if is_wsl() and executable("clip.exe") and executable("powershell.exe") then
    local paste = {
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-Command",
        [[[Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace("`r", ""))]],
    }

    vim.g.clipboard = {
        name = "WslClipboard",
        copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
        paste = { ["+"] = paste, ["*"] = paste },
        cache_enabled = 0,
    }
elseif (
    vim.env.REMOTE_CONTAINERS ~= nil
    or vim.env.DEVPOD ~= nil
    or vim.env.SSH_TTY ~= nil
    or vim.env.SSH_CONNECTION ~= nil
) and not has_native_clipboard() then
    -- Remote terminals can write to the host clipboard via OSC 52 even when
    -- the container has no X11/Wayland server or clipboard executable.
    vim.g.clipboard = "osc52"
end
