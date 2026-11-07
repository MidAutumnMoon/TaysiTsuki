{
    fetchFromGitHub,
    lib,
    stdenvNoCC,
    python3,
}:

let
    # xcursor-size never upscales; bake the common sizes so it resolves.
    sizes = [ 32 48 64 96 128 ];

    assets = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cursor-theme-assets";
        rev = "68147f656d440a9e98d41567826ea2508dd80bf1";
        hash = "sha256-Gilj+SRQfGmflEcVbzfJufayYKWF9KHl5Ij0h/mk1u8=";
    };

    cursor =
        {
            pname,
            version,
            dir,
            description,
            homepage,
        }:

        stdenvNoCC.mkDerivation {
            inherit pname version;
            src = "${assets}/${dir}";

            dontUnpack = true;
            dontBuild = true;
            nativeBuildInputs = [ python3 ];

            installPhase = /*sh*/ ''
                runHook preInstall
                mkdir -p "$out/share/icons"
                cp -r --no-preserve=mode "$src" "$out/share/icons/${dir}"
                python ${./upscale.py} "$src/cursors" "$out/share/icons/${dir}/cursors" ${toString sizes}
                runHook postInstall
            '';

            meta = {
                inherit description homepage;
                license = lib.licenses.unfree;
                platforms = lib.platforms.all;
            };
        };
in
{
    march-7th = cursor {
        pname = "march-7th-cursor";
        version = "0-unstable-2024-06-16";
        dir = "March-7th";
        description = "March 7th from Honkai: Star Rail, as a cursor theme";
        homepage = "https://www.opendesktop.org/p/2165943";
    };

    neuro-sama = cursor {
        pname = "neuro-sama-cursor";
        version = "0-unstable-2025-01-25";
        dir = "Neuro-sama";
        description = "Neuro-sama, as a cursor theme";
        homepage = "https://www.opendesktop.org/p/2167742";
    };

    miku = cursor {
        pname = "miku-cursor-linux";
        version = "1.2.6";
        dir = "miku";
        description = "Hatsune Miku, as a cursor theme";
        homepage = "https://www.opendesktop.org/p/2124099";
    };

    fujita-kotone = cursor {
        pname = "fujita-kotone-cursor";
        version = "0-unstable-2024-06-19";
        dir = "Fujita-Kotone";
        description = "Fujita Kotone from Gakuen iDOLM@STER, as a cursor theme";
        homepage = "https://www.opendesktop.org/p/2166824";
    };

    elaina = cursor {
        pname = "elaina-cursor";
        version = "0-unstable-2026-08-26";
        dir = "elaina";
        description = "Elaina, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    takanashi-hoshino = cursor {
        pname = "takanashi-hoshino-cursor";
        version = "0-unstable-2026-08-22";
        dir = "takanashi-hoshino";
        description = "Takanashi Hoshino from Blue Archive, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    chiyoda-momo = cursor {
        pname = "chiyoda-momo-cursor";
        version = "0-unstable-2026-10-21";
        dir = "chiyoda-momo";
        description = "Chiyoda Momo from The Demon Girl Next Door, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    tendou-alice = cursor {
        pname = "tendou-alice-cursor";
        version = "0-unstable-2026-08-15";
        dir = "tendou-alice";
        description = "Tendou Alice from Blue Archive, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    windows-11-tan = cursor {
        pname = "windows-11-tan-cursor";
        version = "0-unstable-2026-11-02";
        dir = "windows-11-tan";
        description = "Windows 11-tan, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    hanaoka-yuzu = cursor {
        pname = "hanaoka-yuzu-cursor";
        version = "0-unstable-2026-08-12";
        dir = "hanaoka-yuzu";
        description = "Hanaoka Yuzu from Blue Archive, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };

    yoshida-yuko = cursor {
        pname = "yoshida-yuko-cursor";
        version = "0-unstable-2026-10-20";
        dir = "yoshida-yuko";
        description = "Yoshida Yuko, as a cursor theme";
        homepage = "https://space.bilibili.com/4341403";
    };
}
