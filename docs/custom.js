[...document.getElementsByClassName("menu-title")].forEach(it => {
    it.outerHTML = `
        <img class="menu-title" src="https://raw.githubusercontent.com/nix-community/NixOS-WSL/refs/heads/main/assets/NixOS-WSL.svg" alt="NixOS-WSL" />
    `;
});
