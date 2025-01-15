document.addEventListener("DOMContentLoaded", () => {
    let searchTerm = "";
    let matches = [];
    let currentIndex = -1;

    const highlightMatches = () => {
        // Remove previous highlights
        document.querySelectorAll(".highlight").forEach((el) => {
            el.outerHTML = el.textContent; // Replace with original text
        });

        // Add highlights
        matches = [];
        if (searchTerm) {
            // TERRIBLE WAY TO HIGHLIGHT... searching for say "td" fuuus the table... argh
            // clear search box so it isn't messed up, and dont use reference across
            searchBox = document.querySelector("#search-input");
            searchBox.value = "";

            const regex = new RegExp(`(${searchTerm})`, "gi");
            document.body.innerHTML = document.body.innerHTML.replace(
                regex,
                (match, group) => {
                    matches.push(match);
                    return `<span class="highlight">${group}</span>`;
                }
            );

            // restore search box
            searchBox = document.querySelector("#search-input");
            searchBox.value = searchTerm;
        }

        // Style highlights
        const style = document.getElementById("highlight-style");
        if (!style) {
            const styleTag = document.createElement("style");
            styleTag.id = "highlight-style";
            styleTag.innerHTML = `
        .highlight {
          background-color: yellow;
          color: black;
        }
      `;
            document.head.appendChild(styleTag);
        }
    };

    const navigateToMatch = (forward = true) => {
        if (!matches.length) return;

        // Calculate next index
        currentIndex = forward
            ? (currentIndex + 1) % matches.length
            : (currentIndex - 1 + matches.length) % matches.length;

        // Scroll to match
        const highlights = document.querySelectorAll(".highlight");
        if (highlights[currentIndex]) {
            highlights[currentIndex].scrollIntoView({
                behavior: "smooth",
                block: "center",
            });
        }
    };

    const showSearchBox = () => {
        // TODO AFTER I FIX how to highlight... then I can take out defensive code to not reuse search-box/input references

        function removeSearchBox() {
            let searchBox = document.getElementById("search-box");
            if (searchBox) {
                searchBox.remove();
            }
        }
        // add back search box b/c highlight code fux it up (it highlights the text box too ... I could clear that though and put it back... hrm)
        removeSearchBox();

        searchBox = document.createElement("div");
        searchBox.id = "search-box";
        searchBox.style.position = "fixed";
        searchBox.style.top = "10px";
        searchBox.style.left = "10px";
        searchBox.style.background = "white";
        searchBox.style.border = "1px solid black";
        searchBox.style.padding = "10px";
        searchBox.style.zIndex = "1000";

        const input = document.createElement("input");
        input.type = "text";
        input.id = "search-input";
        input.value = searchTerm;
        input.placeholder = "Search for...";
        input.style.marginRight = "10px";
        input.onkeydown = (e) => {
            if (e.key === "Enter") {
                e.preventDefault();
                searchTerm = input.value;
                highlightMatches();
                navigateToMatch(true);
            }
            if (e.key === "Escape") {
                e.preventDefault();
                input.value = "";
                searchTerm = "";
                highlightMatches();
                removeSearchBox();
            }
        };

        searchBox.appendChild(input);
        document.body.appendChild(searchBox);

        // Focus on input
        document.getElementById("search-input").focus();
    };

    // Event listeners for Cmd+G and Cmd+Shift+G
    document.addEventListener("keydown", (e) => {
        if (e.ctrlKey && e.key.toLowerCase() === "f") {
            e.preventDefault();
            showSearchBox();
        } else if (e.ctrlKey && e.key.toLowerCase() === "g") {
            //e.preventDefault();
            if (e.shiftKey) {
                navigateToMatch(false); // Reverse search
            } else {
                navigateToMatch(true); // Next match
            }
        }
    });
});
