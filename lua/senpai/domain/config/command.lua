local M = {}

---@doc.type
---@class senpai.Config.command
---@field deny_list string[]

---@type senpai.Config.command
M.default_config = {
  deny_list = {
    "rm -rf",
    "mkfs",
    "chmod -R 777 /",
    "dd",
    "killall5",
    "shutdown",
    "reboot",
    "passwd",
    "fdisk",
    "parted",
    "useradd",
    "userdel",
    "echo 1 > /proc/sys/kernel/panic",
  },
}

return M
