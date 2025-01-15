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
    // - on first search, or after changing search term... find the next closest match after the current scroll position
    //    - prefer scroll down before up (up == wrap around)

    let searchTerm = "";
    let lastSearchTerm = "";
    let currentIndex = -1; // -1 means first search (with current term)

    function log(...args) {
        // comment out to disable logging
        console.log(...args);
    }

    const highlightMatches = () => {
        if (lastSearchTerm === searchTerm) return;

        // Remove previous highlights
        document.querySelectorAll(".highlight").forEach((el) => {
            el.outerHTML = el.textContent; // Replace with original text
        });
        // clears even if no search term provided, edge case is fine to include

        // Add highlights
        if (searchTerm) {
            log("new searchTerm", searchTerm);
            currentIndex = -1; // Reset current index
            lastSearchTerm = searchTerm;

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
        document
            .querySelectorAll(".currentHighlight")
            .forEach((el) => el.classList.remove("currentHighlight"));

        // FYI I hobbled this together quickly, I wouldn't be surprised if I used the wrong y coordinate for searching for next match, but as long as it works then I don't care
        log("currentIndex before", currentIndex);
        if (currentIndex === -1) {
            // Find first after current scroll position
            const windowScrolledToY = window.scrollY;
            log("  windowScrolledToY", windowScrolledToY);
            // scroll up feels unnatural... so use half of window height b/c then won't scroll up (unless no matches below and some are above)
            // add half the window height to the scroll position, so we don't scroll up
            // - scrolling up indicates the search wrapped and there were no results below
            // - scrolling down indicates results below half way point on page height
            const cutoffY = windowScrolledToY + window.innerHeight / 2;
            log("  cutoffY", cutoffY);
            for (let i = 0; i < highlights.length; i++) {
                const highlight = highlights[i];
                log("    offsetTop", highlight.offsetTop);
                if (highlight.offsetTop > cutoffY) {
                    log("      found", i);
                    currentIndex = i;
                    break;
                } else {
                    log("      not found", i);
                }
            }
            log("new currentIndex", currentIndex);
        } else {
            // Calculate next index
            currentIndex = forward
                ? (currentIndex + 1) % highlights.length
                : (currentIndex - 1 + highlights.length) % highlights.length;
            log("stepping currentIndex", currentIndex);
        }

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
                    log("enter", input.value);
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
