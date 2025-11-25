local ffi = ffi
if not remote then
  --@type CFFIInterface
  ffi = modules.cffi:cffi()
end

---@class GUID
---@field Data1 int
---@field Data2 int
---@field Data3 int
---@field Data4 table<int>

ffi.cdef([[
  typedef struct GUID {
    unsigned long Data1;
    unsigned short Data2;
    unsigned short Data3;
    unsigned char Data4[8];
  } GUID;
]])

---@class SteamMultiplayer_LobbyListEntry
---@field pGUID table<GUID>
---@field hasPassword boolean

---@class DPSESSIONDESC2
---@field guidInstance GUID
---@field lpszPassword integer
ffi.cdef([[
  typedef struct SteamMultiplayer_LobbyListEntry {
    GUID* pGUID;
    bool hasPassword;
  } SteamMultiplayer_LobbyListEntry;

  typedef struct DPSESSIONDESC2 {
    DWORD dwSize;
    DWORD dwFlags;
    GUID guidInstance;
    GUID guidApplication;
    DWORD dwMaxPlayers;
    DWORD dwCurrentPlayers;
    LPWSTR lpszSessionName;
    LPWSTR lpszPassword;
    DWORD* dwReserved1;
    DWORD* dwReserved2;
    DWORD* dwUser1;
    DWORD* dwUser2;
    DWORD* dwUser3;
    DWORD* dwUser4;
  } DPSESSIONDESC2;
]])


---@class CDATA

return {
  sizes = {
    GUID = ffi.sizeof("GUID"),
    SteamMultiplayer_LobbyListEntry = ffi.sizeof("SteamMultiplayer_LobbyListEntry"),
    DPSESSIONDESC2 = ffi.sizeof("DPSESSIONDESC2"),
  }
}