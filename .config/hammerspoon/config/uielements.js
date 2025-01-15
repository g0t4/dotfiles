document.addEventListener("DOMContentLoaded", () => {
    let searchTerm = "";
    let currentIndex = -1;

    const highlightMatches = () => {
        // Remove previous highlights
        document.querySelectorAll(".highlight").forEach((el) => {
            el.outerHTML = el.textContent; // Replace with original text
        });

        // Add highlights
        if (searchTerm) {
            // clear search box so it isn't messed up, and dont use reference across
            // TODO filter out this node in walkNodes...
            searchBox = document.querySelector("#search-input");
            searchBox.value = "";

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
        const highlights = document.querySelectorAll(".highlight");
        if (!highlights.length) return;

        // Calculate next index
        currentIndex = forward
            ? (currentIndex + 1) % highlights.length
            : (currentIndex - 1 + highlights.length) % highlights.length;

        // Scroll to match
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
