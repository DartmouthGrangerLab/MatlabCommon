/**
 * @Copyright 2020 The MathWorks, Inc.
 *
 * tableSort - A lightweight sortable table implementation.
 */

sortable.onclick = function (e) {
    if (e.target.tagName !== 'TH') return;
    if (e.target.dataset.type === 'nosort') return;

    let th = e.target;
    // cellIndex corresponds to the column number.
    // 0 is the first column, 1 is the second column etc.
    sortTable(th.cellIndex, th.dataset.type);
};

function sortTable (colNum, type) {
    let tbody = sortable.querySelector('tbody');

    let rowsArray = Array.from(tbody.rows);

    let compare;

    switch (type) {
        case 'number':
            compare = function (rowA, rowB) {
                return rowA.cells[colNum].innerText - rowB.cells[colNum].innerText;
            };
            break;
        case 'string':
            compare = function (rowA, rowB) {
                return rowA.cells[colNum].innerText > rowB.cells[colNum].innerText ? 1 : -1;
            };
            break;
    }
    rowsArray.sort(compare);
    rowsArray.reverse();
    tbody.append(...rowsArray);
}
