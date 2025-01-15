document.addEventListener("DOMContentLoaded", () => {
    // features I care about (behave as close to browser impl as feasible):
    // - ctrl+f opens search box
    //    - focus is on search right away
    //    - ENTER searches
    //    - focus stays on search box
    //       - THUS, ENTER works to go to next match
    //    - enter/ctrl+g/G should not lose current match position (if same search term)
    //    - Escape closes search box
    // - ctrl+g goes to next match
    // - ctrl+shift+g goes to previous match
    //
    // TODOs
    // - on first search, or after changing search term... find the next closest match after the current scroll position
    //    - get scroll position and then find first after that, compute its currentIndex... bam!

    let searchTerm = "";
    let lastSearchTerm = "";
    let currentIndex = -1;

    const highlightMatches = () => {
        // Remove previous highlights
        document.querySelectorAll(".highlight").forEach((el) => {
            el.outerHTML = el.textContent; // Replace with original text
        });

        // Add highlights
        if (searchTerm && lastSearchTerm !== searchTerm) {
            const regex = new RegExp(`(${searchTerm})`, "gi");

            const highlightClass = "highlight";

            const walkNodes = (node) => {
                if (node.nodeType === Node.TEXT_NODE) {
                    const matches = regex.exec(node.textContent); // Check if there's a match
                    if (matches) {
                        const parent = node.parentNode;

                        // Split the text into before, match, and after parts
                        const textBefore = node.textContent.slice(
                            0,
                            matches.index
                        );
                        const textMatch = node.textContent.slice(
                            matches.index,
                            regex.lastIndex
                        );
                        const textAfter = node.textContent.slice(
                            regex.lastIndex
                        );

                        // Create nodes for each part
                        const beforeNode = document.createTextNode(textBefore);
                        const matchNode = document.createElement("span");
                        matchNode.className = highlightClass;
                        matchNode.textContent = textMatch;
                        const afterNode = document.createTextNode(textAfter);

                        // Insert the new nodes in place of the original text node
                        parent.insertBefore(beforeNode, node);
                        parent.insertBefore(matchNode, node);
                        parent.insertBefore(afterNode, node);
                        parent.removeChild(node);

                        // Continue highlighting the rest of the text
                        regex.lastIndex = 0; // Reset regex for subsequent matches
                        walkNodes(afterNode);
                    }
                } else if (node.nodeType === Node.ELEMENT_NODE) {
                    // Avoid processing script/style elements
                    if (node.tagName !== "SCRIPT" && node.tagName !== "STYLE") {
                        Array.from(node.childNodes).forEach(walkNodes);
                    }
                }
            };

            walkNodes(document.body);
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
        .currentHighlight {
            background-color: red;
        }
      `;
            document.head.appendChild(styleTag);
        }
    };

    const navigateToMatch = (forward = true) => {
        const highlights = document.querySelectorAll(".highlight");
        if (!highlights.length) return;

        // Remove current highlight (play it safe, remove on all instances)
        const currentHighlight = document.querySelector(".currentHighlight");
        if (currentHighlight) {
            currentHighlight.classList.remove("currentHighlight");
        }

        // TODO any way on first search (or search term changed) that we can find first after the current scroll position?

        // Calculate next index
        currentIndex = forward
            ? (currentIndex + 1) % highlights.length
            : (currentIndex - 1 + highlights.length) % highlights.length;

        const nextHighlight = highlights[currentIndex];
        if (nextHighlight) {
            nextHighlight.classList.add("currentHighlight");
            nextHighlight.scrollIntoView({
                behavior: "smooth",
                block: "center",
            });
        }
    };

    const showSearchBox = () => {
        let searchBox = document.getElementById("search-box");
        if (!searchBox) {
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
                    searchBox.remove();
                }
            };

            searchBox.appendChild(input);
            document.body.appendChild(searchBox);
        }

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
