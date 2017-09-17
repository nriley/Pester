var IMG_BLANK = 'blank.png';


function hover(iNode, over) {
    var theme = $('body').attr("data-theme");
    if (theme == 'light') {
        img_expanded = 'Expanded.png';
        img_collapsed = 'Collapsed.png';
        img_leaf = 'LeafRowHandle.png';
    } else if (theme == 'dark') {
        img_expanded = 'Expanded-dark.png';
        img_collapsed = 'Collapsed-dark.png';
        img_leaf = 'LeafRowHandle-dark.png';
    }
    
    if (over) {
        t = document.getElementById(iNode).alt;
        
        if (t == '*') {
            document.getElementById(iNode).src=img_leaf;
        } else if (t == 'V') {
            document.getElementById(iNode).src=img_expanded;
        } else {
            document.getElementById(iNode).src=img_collapsed;
        }
        
    } else {
        document.getElementById(iNode).src=IMG_BLANK;
    }
}

function expand(ioNode, fully) {
    var theme = $('body').attr("data-theme");
    if (theme == 'light') {
        img_expanded = 'Expanded.png';
    } else if (theme == 'dark') {
        img_expanded = 'Expanded-dark.png';
    }
    ioWedge = "i" + ioNode;
    
    if ($("#" + ioNode)[0] !=  null) {
        /* In case the wrapper gets left around by interrupting the slide up/down */
        $('div.temp-wrapper').contents().unwrap();
        $('div.temp').contents().unwrap();
        
        var row = $("#" + ioNode)[0];
        var baseLevel = Number($(row).attr("data-level"));
        var nextRow = $(row).next()[0];
        var noteRow = $("#n" + ioNode)[0];
        var previousLevel = baseLevel;
        var parentExpansionState = "expanded";
        var parentVisibilityState = "visible";
        var rowsBeingRevealed = [];
        
        if (nextRow != null) {
            // Check following sibling elements and see if its level is greater than the parent clicked
            // If so, for immediate children rows, make them visible
            // The row's note is first included just to make sure we interate past it
            while ((nextRow != null) && (($(nextRow).attr("data-level") > baseLevel) || $(nextRow).hasClass('whole-note'))) {
                if (!(($(nextRow).hasClass('whole-note')) && ($(nextRow).attr("data-level") == baseLevel))) {
                    rowsBeingRevealed.push(nextRow);
                }
                // Advanced nextRow to next sibling
                nextRow = $(nextRow).next()[0]
            }
        }
        
        $(rowsBeingRevealed)
        .wrapAll('<div class="temp" style="display: none;" id=' + 'div' + ioNode + ' />')
        .wrapAll('<div class="temp-wrapper" style="display: inline-block;" />');
        
        for (var i = 0; i < rowsBeingRevealed.length; i++) {
            if (fully == true) {
                if (!$(rowsBeingRevealed[i]).hasClass("whole-note")) {
                    $(rowsBeingRevealed[i]).attr("data-state", "expanded");
                }
            }
            // Make notes visible if their coresponding row is set to be visible and note is expanded
            if ($(rowsBeingRevealed[i]).hasClass("whole-note")) {
                if (($(rowsBeingRevealed[i]).attr("data-state") == "expanded") && ($(rowsBeingRevealed[i]).prev().hasClass("visible"))) {
                    $(rowsBeingRevealed[i]).removeClass("hidden").addClass("visible");
                }
            }
            else {
                // Check following sibling elements and see if its level is greater than the parent clicked
                // If so, for immediate children rows, make them visible
                var currentLevel = Number($(rowsBeingRevealed[i]).attr("data-level"));
                // make immediate children visible
                if (currentLevel == (baseLevel + 1)) {
                    $(rowsBeingRevealed[i]).removeClass("hidden").addClass("visible");
                    $(rowsBeingRevealed[i]).addClass("visible");
                }
                // When child rows have children, check for expansion state and set its children accordingly
                else if (currentLevel > previousLevel) {
                    if ((parentExpansionState == "expanded") && (parentVisibilityState == "visible")) {
                        $(rowsBeingRevealed[i]).removeClass("hidden").addClass("visible");
                    }
                }
                else if (currentLevel <= previousLevel) {
                    var foundParent = 0;
                    var previousRow = $(rowsBeingRevealed[i]).prev()[0];
                    // Locate the parent of the row in question to see if the row should be visible or not
                    while (foundParent != 1) {
                        if (($(previousRow).attr("data-level") == (currentLevel - 1)) && !($(previousRow).hasClass("whole-note"))) {
                            if ($(previousRow).hasClass("visible") && ($(previousRow).attr("data-state") == "expanded")) {
                                $(rowsBeingRevealed[i]).removeClass("hidden").addClass("visible");
                            }
                            foundParent = 1;
                        }
                        else {
                            previousRow = $(previousRow).prev()[0];
                        }
                        
                    }
                }
            }
            // save level and state of current row to evaluate as the parent of the next row
            previousLevel = currentLevel;
            if ($(rowsBeingRevealed[i]).next() && ($(rowsBeingRevealed[i]).next().attr("data-level") > currentLevel)) {
                // Check if previous row is a note, if so we need to look at the note's outline row instead of the note
                if ($(rowsBeingRevealed[i]).hasClass("whole-note")) {
                    parentExpansionState = $(rowsBeingRevealed[i]).prev().attr("data-state");
                    if ($(rowsBeingRevealed[i]).prev().hasClass("visible")) {
                        parentVisibilityState = "visible";
                    } else {
                        parentVisibilityState = "hidden";
                    }
                }
                else {
                    parentExpansionState = $(rowsBeingRevealed[i]).attr("data-state");
                    if ($(rowsBeingRevealed[i]).hasClass("visible")) {
                        parentVisibilityState = "visible";
                    } else {
                        parentVisibilityState = "hidden";
                    }
                }
            }
        }
        
        
        $('#div' + ioNode)
        .stop()
        .slideDown(150)
        .promise().always(function() {
                          $('.temp-wrapper').contents().unwrap().unwrap();
                          // Remove last-child classes
                          // If the note row has the "last-child" class then it should be visible
                          if ((noteRow != null) && ($(noteRow).hasClass("last-child"))) {
                          $(noteRow).removeClass("last-child");
                          }
                          // Can only have last-child class if the row's note is collapsed or doesn't exist
                          if ($(row).hasClass("last-child")) {
                          $(row).removeClass("last-child");
                          }
                          // Update "last-child" class on expanded rows
                          setLastChildClass(rowsBeingRevealed);
                          // Update alt row colors
                          updateRowBackgroundColors();
                          });
        
        
        $(row).attr("data-state", "expanded");
        
        if ($("#" + ioWedge)[0] !=  null) {
            $("#" + ioWedge).attr({
                                  src: img_expanded,
                                  title: "collapse",
                                  alt: "V"
                                  });
        }
        
        // Modify padding values
        /* Custom values to consider:
         Removing below children
         Adding above children
         */
        
        var inlineRowPadding = $(row).attr("data-bottom-padding");
        var inlineAboveNotePadding = $(row).attr("data-above-note");
        var inlineAboveChildrenPadding = $(row).attr("data-above-children");
        var inlineBelowChildrenPadding = $(row).attr("data-below-children");
        
        
        var nextRow;
        if (noteRow == null) {
            nextRow = $(row).next()[0];
        } else {
            nextRow = $(noteRow).next()[0];
        }
        
        if ((inlineAboveChildrenPadding != "") || (inlineBelowChildrenPadding != "")) {
            // If there's a note and it is visible
            if ((noteRow != null) && $(noteRow).hasClass("visible")) {
                if ($(row).attr("data-has-children") == 1) { // these children are now visible
                    if ((inlineRowPadding == "") && (inlineAboveChildrenPadding == "")) {
                        // Remove inline top/bottom padding and let the default styling apply
                        removePadding(noteRow, "note");
                    } else {
                        setBottomPadding(noteRow, "note", ((getNum(inlineRowPadding) + getNum(inlineAboveChildrenPadding)) + "px"));
                    }
                }
            } else {
                // No visible note
                if ($(row).attr("data-has-children") == 1) { // these children are now visible
                    if ((inlineRowPadding == "") && (inlineAboveChildrenPadding == "")) {
                        // Remove inline top/bottom padding and let the default styling apply
                        removePadding(row, "row");
                    } else {
                        setBottomPadding(row, "row", ((getNum(inlineRowPadding) + getNum(inlineAboveChildrenPadding)) + "px"));
                    }
                    
                }
            }
        }
        
    }
}

function collapse(ioNode, fully) {
    theme = $('body').attr("data-theme");
    if (theme == 'light') {
        img_collapsed = 'Collapsed.png';
    } else if (theme == 'dark') {
        img_collapsed = 'Collapsed-dark.png';
    }
    ioWedge = "i" + ioNode;
    
    if ($("#" + ioNode)[0] !=  null) {
        /* In case the wrapper gets left around by interrupting the slide up/down */
        $('div.temp-wrapper').contents().unwrap();
        $('div.temp').contents().unwrap();
        
        var row = $("#" + ioNode)[0];
        var baseLevel = Number($(row).attr("data-level"));
        var nextRow = $(row).next()[0];
        var rowsToCollapse = [];
        
        if (nextRow != null) {
            while ((nextRow != null) && (($(nextRow).attr("data-level") > baseLevel) || ($(nextRow).hasClass('whole-note')))) {
                // For collapsing, can just set all descendants to hidden but not its own note
                if (!($(nextRow).hasClass("whole-note") && ($(nextRow).attr("data-level") == baseLevel))) {
                    rowsToCollapse.push(nextRow);
                }
                nextRow = $(nextRow).next()[0];
            }
        }
        
        $(rowsToCollapse)
        .wrapAll('<div class="temp" style="display: block;" id=' + 'div' + ioNode + ' />')
        .wrapAll('<div class="temp-wrapper" style="display: inline-block;" />');
        
        
        $('#div' + ioNode)
        .stop()
        .slideUp(150)
        .promise().always(function() {
                          $('.temp-wrapper').contents().unwrap().unwrap();
                          for (var i = 0; i < rowsToCollapse.length; i++) {
                          $(rowsToCollapse[i]).removeClass("visible last-child").addClass("hidden");
                          }
                          // Update alt row colors
                          updateRowBackgroundColors();
                          });
        
        $(row).attr("data-state", "collapsed");
        
        if (fully == true) {
            $(rowsToCollapse).each(function() {
                                   $(this).removeClass("visible last-child").addClass("hidden");
                                   if (!$(this).hasClass("whole-note")) {
                                       $(this).attr("data-state", "collapsed");
                                   }
                                   if ($("#i" + $(this).attr("id"))[0] !=  null) {
                                   $("#i" + $(this).attr("id")).attr({
                                                                     src: img_collapsed,
                                                                     title: "expand",
                                                                     alt: ">"
                                                                     })
                                   }
                                   });
        }
        
        if ($("#" + ioWedge)[0] !=  null) {
            $("#" + ioWedge).attr({
                                  src: img_collapsed,
                                  title: "expand",
                                  alt: ">"
                                  })
        }
        
        
        var element = row;
        var foundNextVisible = false;
        var visibleRows = [row];
        while (foundNextVisible === false) {
            // Get next visible sibling
            if ($(element).next()[0] != null) {
                if ($(element).next().hasClass("visible")) {
                    foundNextVisible = true;
                    setLastChildClass([row, $(element).next()[0]]);
                    break;
                } else {
                    element = $(element).next()[0];
                }
            } else {
                break;
            }
        }
        
        
        // Modify inline padding values.
        /* Custom values to consider:
         Adding below children
         Removing above children
         */
        var inlineRowPadding = $(row).attr("data-bottom-padding");
        var inlineAboveNotePadding = $(row).attr("data-above-note");
        var inlineAboveChildrenPadding = $(row).attr("data-above-children");
        var inlineBelowChildrenPadding = $(row).attr("data-below-children");
        
        var noteRow = $("#n" + ioNode)[0];
        
        // Add inline below children padding to row if applicable. Can only have last-child class if the row's note is collapsed or doesn't exist. "last-child" class has been updated so just need to see if it exists.
        if ((inlineAboveChildrenPadding != "") || (inlineBelowChildrenPadding != "")) {
            // If there's a note and it is visible
            if ((noteRow != null) && $(noteRow).hasClass("visible")) {
                if ((inlineRowPadding == "") && (inlineBelowChildrenPadding == "")) {
                    // Let the default styling apply
                    removePadding(noteRow, "note");
                } else {
                    if ($(noteRow).hasClass("last-child")) {
                        setBottomPadding(noteRow, "note", ((getNum(inlineRowPadding) + getNum(inlineBelowChildrenPadding)) + "px"));
                    } else {
                        if (inlineRowPadding != "") {
                            setBottomPadding(noteRow, "note", (getNum(inlineRowPadding) + "px"));
                        } else {
                            // Let the default styling apply
                            removePadding(row, "row");
                        }
                    }
                }
            } else {
                // No visible note
                if ((inlineRowPadding == "") && (inlineBelowChildrenPadding == "")) {
                    // Let the default styling apply
                    removePadding(row, "row");
                } else {
                    if ($(row).hasClass("last-child")) {
                        setBottomPadding(row, "row", ((getNum(inlineRowPadding) + getNum(inlineBelowChildrenPadding)) + "px"));
                    } else {
                        if (inlineRowPadding != "") {
                            setBottomPadding(row, "row", (getNum(inlineRowPadding) + "px"));
                        } else {
                            // Let the default styling apply
                            removePadding(row, "row");
                        }
                    }
                }
            }
        }
    }
}

function ioSwitch(ioNode,fully) {
    var node = $("#" + ioNode);
    var nodeState;
    
    if (node[0] != null) {
        nodeState = node.attr("data-state");
    }
    
    if (nodeState.indexOf('collapsed') >= 0) {
        if (fully) {
            expandAll();
        } else {
            expand(ioNode);
        }
    }
    
    else {
        if (fully) {
            collapseAll();
        } else {
            collapse(ioNode);
        }
    }
}

function expandAll() {
    var allCollapsedParents = $(".whole-row").filter("[data-has-children = '1']").filter("[data-state = 'collapsed']");
    
    allCollapsedParents.each(function() {
                             expand($(this).attr("id"), true);
                             });
    setLastChildClass();
    
}

function collapseAll() {
    // Just need to collapse level 1 rows as the rest is taken care of during the collapse
    var allLevel1Parents = $(".whole-row").filter("[data-level = '1']").filter("[data-has-children = '1']").filter("[data-state = 'expanded']");
    
    allLevel1Parents.each(function() {
                          collapse($(this).attr("id"), true);
                          });
}

// Look into using an animation queue to get toggling of all notes animating
function toggleNote(ioNode,fully) {
    var noteId = "n" + ioNode;
    var note = document.getElementById(noteId);
    var noteState = note.getAttribute("data-state");
    
    // Either hide or show all, depending on what the state of the note is that it was activated from
    if (fully) {
        allNotes = document.getElementsByClassName("whole-note");
        for (var i = 0; i < allNotes.length; i++) {
            // Hidding all notes
            if (noteState == "expanded") {
                hideNote(allNotes[i].id);
            }
            // Showing all notes
            else if (noteState == "collapsed") {
                var rowId = allNotes[i].id.substring(1);
                if ($("#" + rowId).hasClass("visible")) {
                    showNote(allNotes[i].id);
                }
            }
        }
    } else {
        if (noteState == "expanded") {
            hideNote(noteId);
        } else if (noteState == "collapsed") {
            showNote(noteId);
        }
    }
}

function showNote (ioNode) {
    var noteId = ioNode;
    var note = document.getElementById(noteId);
    var noteState = note.getAttribute("data-state");
    var idOfRow = noteId.slice(1);
    var noteParentRow = document.getElementById(idOfRow);
    
    var inlineRowPadding = $(noteParentRow).attr("data-bottom-padding");
    var inlineAboveNotePadding = $(noteParentRow).attr("data-above-note");
    var inlineAboveChildrenPadding = $(noteParentRow).attr("data-above-children");
    var inlineBelowChildrenPadding = $(noteParentRow).attr("data-below-children");
    
    /* In case the wrapper gets left around by interrupting the slide up/down */
    $('div.temp-wrapper').contents().unwrap();
    $('div.temp').contents().unwrap();
    
    
    $(note)
    .wrapAll('<div class="temp" style="display: none;" id=' + 'div' + ioNode + ' />')
    .wrapAll('<div class="temp-wrapper" style="display: block;" />');
    
    $(note).removeClass("hidden")
    .addClass("visible")
    .attr("data-state", "expanded");
    
    $(noteParentRow).addClass("note-expanded");
    
    $('#div' + ioNode)
    .slideDown(150, function() {
               $('.temp-wrapper').contents().unwrap().unwrap();
               }
               );
    
    /* Custom padding values to consider:
     Adding above note to the row
     Adding row padding to the note, removing from row
     Adding above/below children to the note, removing from the row
     */
    
    // Always remove padding from the note's parent, then add any non-default padding
    removePadding(noteParentRow, "row");
    if (inlineAboveNotePadding != "") {
        setBottomPadding(noteParentRow, "row", (getNum(inlineAboveNotePadding) + "px"));
    }
    if (inlineRowPadding != "") {
        setTopPadding(noteParentRow, "row", (getNum(inlineRowPadding) - 1 + "px"));
    }
    
    if ($(noteParentRow).hasClass("last-child")) {
        $(note).addClass("last-child");
        $(noteParentRow).removeClass("last-child");
        
        // Modify the bottom padding of the note
        if ((inlineRowPadding != "") || (inlineBelowChildrenPadding != "")) {
            setBottomPadding(note, "note", ((getNum(inlineRowPadding) + getNum(inlineBelowChildrenPadding)) + "px"));
        }
    } else {
        // Check if above children or row padding needs to be applied
        if (($(noteParentRow).attr("data-has-children") == 1) && ($(noteParentRow).attr("data-state") == "expanded")) {
            if ((inlineRowPadding != "") || (inlineAboveChildrenPadding != "")) {
                setBottomPadding(note, "note", ((getNum(inlineRowPadding) + getNum(inlineAboveChildrenPadding)) + "px"))
            }
        }
    }
}

function hideNote (ioNode) {
    var noteId = ioNode;
    var note = document.getElementById(noteId);
    var noteState = note.getAttribute("data-state");
    var idOfRow = noteId.slice(1);
    var noteParentRow = document.getElementById(idOfRow);
    
    var inlineRowPadding = $(noteParentRow).attr("data-bottom-padding");
    var inlineAboveNotePadding = $(noteParentRow).attr("data-above-note");
    var inlineAboveChildrenPadding = $(noteParentRow).attr("data-above-children");
    var inlineBelowChildrenPadding = $(noteParentRow).attr("data-below-children");
    
    /* In case the wrapper gets left around by interrupting the slide up/down */
    $('div.temp-wrapper').contents().unwrap();
    $('div.temp').contents().unwrap();
    
    
    $(note)
    .wrapAll('<div class="temp" style="display: block;" id=' + 'div' + ioNode + ' />')
    .wrapAll('<div class="temp-wrapper" style="display: block;" />');
    
    $('#div' + ioNode)
    .slideUp(150, function() {
             $('.temp-wrapper').contents().unwrap().unwrap();
             $(note).removeClass("visible")
             .addClass("hidden")
             .attr("data-state", "collapsed");
             $(noteParentRow).removeClass("note-expanded");
             });
    
    /* Custom padding values to consider:
     Removing above note
     Adding row padding to row
     Adding above/below children to row
     */
    
    if ($(note).hasClass("last-child")) {
        $(note).removeClass("last-child");
        $(noteParentRow).addClass("last-child");
        removePadding(note, "note");
        // Modifying noteParentRow padding if row padding or below child padding is non-gobal-default
        if ((inlineRowPadding != "") || (inlineBelowChildrenPadding != "")) {
            setBottomPadding(noteParentRow, "row", ((getNum(inlineRowPadding) + getNum(inlineBelowChildrenPadding)) + "px"));
        }
    } else {
        // Not last child, so check if there are any visible children
        if (($(noteParentRow).attr("data-has-children") == 1) && $(noteParentRow).attr("data-state") == "expanded") {
            // Above children and row padding matter
            if ((inlineAboveChildrenPadding != "") || (inlineRowPadding != "")) {
                setBottomPadding(noteParentRow, "row", ((getNum(inlineRowPadding) + getNum(inlineAboveChildrenPadding)) + "px"));
            }
        } else if (inlineRowPadding != "") {
            // if nothing else, check for custom row padding
            setBottomPadding(noteParentRow, "row", (getNum(inlineRowPadding) + "px"));
        }
    }
}

function setBottomPadding(row, type, paddingValue) {
    if (type == 'row') {
        row.getElementsByClassName("outline-column")[0].getElementsByTagName('td')[3].style.paddingBottom = paddingValue;
    } else if (type == 'note') {
        row.getElementsByClassName("note-table")[0].getElementsByTagName('td')[3].style.paddingBottom = paddingValue;
    }
}

function setTopPadding(row, type, paddingValue) {
    if (type == 'row') {
        row.getElementsByClassName("outline-column")[0].getElementsByTagName('td')[3].style.paddingTop = paddingValue;
    } else if (type == 'note') {
        row.getElementsByClassName("note-table")[0].getElementsByTagName('td')[3].style.paddingTop = paddingValue;
    }
}

function removePadding(row, type) {
    if (type == 'row') {
        row.getElementsByClassName("outline-column")[0].getElementsByTagName('td')[3].style.removeProperty("padding-bottom");
        row.getElementsByClassName("outline-column")[0].getElementsByTagName('td')[3].style.removeProperty("padding-top");
    } else if (type == 'note') {
        row.getElementsByClassName("note-table")[0].getElementsByTagName('td')[3].style.removeProperty("padding-bottom");
    }
}


function updateRowBackgroundColors() {
    // do not update row colors unless alternate row colors has been specified.
    if (!$(document.body).hasClass("alt-row-colors"))
        return;
    var possibleRows = document.getElementsByClassName("whole-row");
    var rowCount = 0;
    for(var i = 0; i < possibleRows.length; i++) {
        var element = possibleRows[i];
        var elementNote = document.getElementById("n" + element.id);
        if ($(element).hasClass("visible")) {
            rowCount++;
            if (rowCount % 2 == 0) {
                $(element).addClass("alt-row");
                if (elementNote != null) {
                    $(elementNote).addClass("alt-row");
                }
            } else {
                $(element).removeClass("alt-row");
                if (elementNote != null) {
                    $(elementNote).removeClass("alt-row");
                }
            }
        }
    }
}

function setVisibility() {
    if (document.getElementsByTagName) {
        var allRows = document.querySelectorAll("table.whole-row, table.whole-note");
        
        for(var i = 0; i < allRows.length; i++) {
            var element = allRows[i];
            // Deal with root rows
            if ($(element).hasClass("root")) {
                $(element).addClass("visible");
            }
            // Deal with note rows which will never be the very first row
            else if ($(element).hasClass("whole-note")) {
                if ((element.getAttribute("data-state") == "expanded") && ($(element).prev().hasClass("visible"))) {
                    $(element).addClass("visible");
                    var idOfRow = element.id.substring(1);
                    var noteParentRow = document.getElementById(idOfRow);
                    $(noteParentRow).addClass("note-expanded");
                }
                else {
                    $(element).addClass("hidden");
                }
            }
            // Deal with non-root rows
            else {
                var currentLevel = Number(element.getAttribute("data-level"));
                var previousRow = element.previousElementSibling;
                if (previousRow != null) {
                    var foundParent = 0;
                    while (foundParent != 1) {
                        if (($(previousRow).attr("data-level") == (currentLevel - 1)) && !($(previousRow).hasClass("whole-note"))) {
                            if ($(previousRow).hasClass("visible") && ($(previousRow).attr("data-state") == "expanded")) {
                                $(element).addClass("visible");
                            }
                            else {
                                $(element).addClass("hidden");
                            }
                            foundParent = 1;
                        }
                        else {
                            previousRow = previousRow.previousElementSibling;
                        }
                        
                    }
                }
                else {
                    $(element).addClass("visible");
                }
            }
        }
    }
    else {
        alert ("Can't set row visibility. Unable to run this in your browser, sorry.");
    }
}

function setLastChildClass(rowSet) {
    // This is used for setting "Below children" padding
    var rows = [];
    if (rowSet == null) {
        rows = $('table.whole-row.visible, table.whole-note.visible');
    } else {
        rows = $(rowSet).filter('.visible');
    }
    $(rows).each(function() {
                 var element = $(this);
                 var siblingCount = $(element).siblings().length;
                 for (var i = 0; i < siblingCount; i++) {
                 // Get next visible sibling in the whole DOM
                 if ($(element).next()[0] != null) {
                 if ($(element).next().hasClass("visible")) {
                 // See if the next visible sibling is of a numerically lower data-level
                 if ($(element).next().attr("data-level") < $(this).attr("data-level")) {
                 $(this).addClass("last-child");
                 }
                 break;
                 } else {
                 element = $(element).next();
                 }
                 } else {
                 break;
                 }
                 }
                 });
}


function setWidths() {
    var everyRow = document.querySelectorAll("table.whole-row, table.whole-note");
    var previousLevel = 1;
    var everyCellToModify = [];
    for (var i = 0; i < everyRow.length; i++) {
        // Set level 1 row widths
        if (i == 0) {
            everyCellToModify.pushArray(setWidthsForSectionLevel(everyRow[0]));
        } else {
            var nextRow = everyRow[i].nextElementSibling;
            var thisDataLevel = everyRow[i].getAttribute("data-level");
            // Set widths for all other row levels
            if (thisDataLevel > previousLevel) {
                everyCellToModify.pushArray(setWidthsForSectionLevel(everyRow[i]));
                previousLevel = thisDataLevel;
            } else if ((nextRow !== null) && (thisDataLevel < previousLevel)) {
                // Should have already adjust this row but we need to check for children
                previousLevel = thisDataLevel;
            }
        }
    }
    for (var i = 0; i < everyCellToModify.length; i++) {
        everyCellToModify[i][0].style.width = (everyCellToModify[i][1] + "px");
        if (everyCellToModify[i][1] > 1) {
            $(everyCellToModify[i][0]).removeClass("empty");
        }
    }
}

function setWidthsForSectionLevel(startRow) {
    var currentLevel = Number($(startRow).attr("data-level"));
    var everyRowOfLevelInSection = [];
    var everyLabelTdInSection = [];
    var stillInSection = true;
    var labelTd = startRow.querySelectorAll("td.label")[0];
    everyLabelTdInSection.push(labelTd);
    var styleOfLabelTd = window.getComputedStyle(labelTd, null);
    everyRowOfLevelInSection.push(startRow);
    var maxWidth = parseInt(styleOfLabelTd.getPropertyValue("width"));
    var currentRow = startRow;
    while (stillInSection == true) {
        var nextRow = currentRow.nextElementSibling;
        var thisDataLevel = (nextRow != null) ? Number(currentRow.nextElementSibling.getAttribute("data-level")) : null;
        if (thisDataLevel ==  currentLevel) {
            everyRowOfLevelInSection.push(nextRow);
            labelTd = nextRow.querySelectorAll("td.label")[0];
            everyLabelTdInSection.push(labelTd);
            styleOfLabelTd = window.getComputedStyle(labelTd, null);
            var width = parseInt(styleOfLabelTd.getPropertyValue("width"));
            
            if (width > maxWidth) {
                maxWidth = width;
            }
        } else if ((nextRow == null) || (thisDataLevel < currentLevel))  {
            stillInSection = false;
        }
        currentRow = nextRow;
    }
    
    var cellsToModify = [];
    for (var i = 0; i < everyLabelTdInSection.length; i++) {
        cellsToModify.push([everyLabelTdInSection[i], maxWidth]);
    }
    return cellsToModify;
}

function setOutlineTitleInset() {
    var headerRow = document.getElementById("header");
    var firstRow = document.querySelector("table.whole-row");
    var outlineTitleDiv = document.getElementById("outlineInset");
    if (outlineTitleDiv != null) {
        var firstRowOutlineCells = firstRow.querySelector("table.outline-column").getElementsByTagName("td");
        var insetWidth = 0;
        for (var i = 0; i < (firstRowOutlineCells.length - 1); i++) {
            var width = parseInt(firstRowOutlineCells[i].offsetWidth);
            insetWidth = insetWidth + width;
        }
        outlineTitleDiv.style.paddingLeft = (insetWidth + "px");
    }
}

function ieScript() {
    if ((!!navigator.userAgent.match(/Edge\/\d+/i)) || (!!navigator.userAgent.match(/Trident\/\d+/i))){
        //Set the height of table rows for IE and Edge
        var everyRow = document.querySelectorAll("table#outline > tbody > tr");
        var everyRowHeight = [];
        for (var i = 0; i < everyRow.length; i++) {
            everyRowHeight.push(everyRow[i].offsetHeight);
        }
        for (var i = 0; i< everyRow.length; i++) {
            everyRow[i].style.height = everyRowHeight[i] + "px";
        }
    }
}



function getNum(val) {
    if (isNaN(val)) {
        return 0;
    }
    return Number(val);
}

Array.prototype.pushArray = function() {
    var toPush = this.concat.apply([], arguments);
    for (var i = 0, len = toPush.length; i < len; ++i) {
        this.push(toPush[i]);
    }
};

function setup() {
    setWidths(); // Run this before setting visiblity so all rows are visible at time of calculation
    ieScript();  // This too
    setOutlineTitleInset();
    setVisibility();
    setLastChildClass();
    updateRowBackgroundColors();
}

window.onload = setup;


