newoption {
    trigger     = "window-manager",
    value       = "WM",
    description = "Choose a window manager for Linux (options: wayland, x11)",
    allowed     = {
        { "wayland", "Wayland" },
        { "x11", "X11" }
    },
    default     = "x11"
}

-- Define a function to find Wayland scanner executable
function findWaylandScanner()
    local paths = os.getenv("PATH")
    for path in paths:gmatch("[^:]+") do
        local fullPath = path .. "/wayland-scanner"
        if os.isfile(fullPath) then
            return fullPath
        end
    end
    return nil
end

project "GLFW"
    kind "StaticLib"
    language "C"
    staticruntime "off"
	warnings "off"

    targetdir("bin/" .. outputdir .. "/%{prj.name}")
    objdir("obj/" .. outputdir .. "/%{prj.name}")

    files {
        "include/GLFW/glfw3.h",
        "include/GLFW/glfw3native.h",
        
        "src/internal.h",
        "src/platform.h",
        "src/mappings.h",
        "src/null_joystick.h",
        "src/null_platform.h",

        "src/context.c",
        "src/init.c",
        "src/input.c",
        "src/monitor.c",

        "src/null_init.c",
        "src/null_joystick.c",
        "src/null_monitor.c",
        "src/null_window.c",
        "src/null_platform.h",

        "src/platform.c",
        "src/vulkan.c",
        "src/window.c",
    }



    filter "system:linux"
        pic "On"
        systemversion "latest"

        files
        {
            "src/linux_joystick.h",
            "src/xkb_unicode.h",
            "src/posix_module.c",
			"src/posix_time.c",
			"src/posix_thread.c",
			"src/posix_module.c",
            "src/linux_joystick.c",
            "src/xkb_unicode.c",
            "src/egl_context.c",
            "src/osmesa_context.c",
        }

        filter { "options:window-manager=wayland" }
            if _OPTIONS["window-manager"] == "wayland" then
                -- Check for memfd_create function
                local haveMemfdCreate = os.isfile("stdio.h")
                if haveMemfdCreate then
                    defines { "HAVE_MEMFD_CREATE" }
                end
            
                -- Find the Wayland scanner executable
                local waylandScannerExecutable = findWaylandScanner()
                if not waylandScannerExecutable then
                    error("Failed to find wayland-scanner")
                end
            
            
                -- Define a function to generate Wayland protocol files
                local function generateWaylandProtocol(protocolFile)
                    local protocolPath = path.join(_MAIN_SCRIPT_DIR, "GloryEngine" , "vendor", "GLFW", "deps", "wayland", protocolFile)
            
                    local headerFile = protocolFile:gsub("%.xml$", "-client-protocol.h")
                    local codeFile = protocolFile:gsub("%.xml$", "-client-protocol-code.h")
            
                    local command1 = '"' .. waylandScannerExecutable .. '" client-header "' .. protocolPath .. '" ' .. "src/" .. headerFile
                    local command2 = '"' .. waylandScannerExecutable .. '" private-code "' .. protocolPath .. '" ' .. "src/" .. codeFile
            
                    prebuildcommands {
                        command1,
                        command2
                    }
            
                    files {
                        path.join(_MAIN_SCRIPT_DIR,"GloryEngine" , "vendor", "GLFW", "src" , headerFile),
                        path.join(_MAIN_SCRIPT_DIR,"GloryEngine" , "vendor", "GLFW" ,"src", codeFile)
                    }
                end
        
                -- Generate Wayland protocol files
                generateWaylandProtocol("wayland.xml")
                generateWaylandProtocol("viewporter.xml")
                generateWaylandProtocol("xdg-shell.xml")
                generateWaylandProtocol("idle-inhibit-unstable-v1.xml")
                generateWaylandProtocol("pointer-constraints-unstable-v1.xml")
                generateWaylandProtocol("relative-pointer-unstable-v1.xml")
                generateWaylandProtocol("fractional-scale-v1.xml")
                generateWaylandProtocol("xdg-activation-v1.xml")
                generateWaylandProtocol("xdg-decoration-unstable-v1.xml")
            end

            files
            {
                "src/wl_platform.h",
                "src/wl_init.c",
                "src/wl_monitor.c",
                "src/wl_window.c",
            }

            defines
            {
                "_GLFW_WAYLAND"
            }
        filter { "options:window-manager=x11" }
            files
            {
                "src/x11_platform.h",
                "src/x11_init.c",
                "src/x11_monitor.c",
                "src/x11_window.c",
                "src/glx_context.c"
            }
            defines
            {
                "_GLFW_X11"
            }


    filter "system:windows"
        systemversion "latest"

        files
        {
            "src/win32_*.c",
            "src/wgl_context.c",
            "src/egl_context.c",
            "src/osmesa_context.c"
        }

        defines
        {
            "_GLFW_WIN32",
            "_CRT_SECURE_NO_WARNINGS"
        }
