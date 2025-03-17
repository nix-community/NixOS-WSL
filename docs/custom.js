[...document.getElementsByClassName("menu-title")].forEach(it => {
    it.outerHTML = `
        <img class="menu-title" src="./NixOS-WSL.svg" alt="NixOS-WSL" />
    `;
});
