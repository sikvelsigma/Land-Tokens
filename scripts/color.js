"use strict"
/* Examples of colored strings:
    "<r>Red <g>green"
    "<bld><r>Red and bold <g>green and bold"
    "<bld><r>Red and bold <clr><g>green"
*/
const styles = {
    clr       : '\x1b[0m', // clear
    clear     : '\x1b[0m',

    bld      : '\x1b[1m', // bold
    fdd       : '\x1b[2m', // faded
    itl       : '\x1b[3m', // italic
    und      : '\x1b[4m', // underscore
    sfl       : '\x1b[5m', // slow flash
    ffl       : '\x1b[6m', // fast flash
    inv       : '\x1b[7m', // invert text and background color

    // Text styles
    blk   : '\x1b[30m', // black
    black : '\x1b[30m',
    k     : '\x1b[30m',

    red   : '\x1b[31m', // red
    r     : '\x1b[31m',

    grn   : '\x1b[32m', // green
    green : '\x1b[32m', 
    g     : '\x1b[32m',

    yel   : '\x1b[33m', // yellow
    yellow: '\x1b[33m',
    y     : '\x1b[33m',

    blue  : '\x1b[34m', // blue
    b     : '\x1b[34m',

    prp   : '\x1b[35m', // purple
    purple: '\x1b[35m',
    m     : '\x1b[35m',

    trq   : '\x1b[36m', // cyan
    cyan  : '\x1b[36m',
    c     : '\x1b[36m',

    wht   : '\x1b[37m', // white
    white : '\x1b[37m', 
    w     : '\x1b[37m',

    // Background styles
    blk_f : '\x1b[40m', // black
    kf    : '\x1b[40m',

    red_f : '\x1b[41m', // red
    rf    : '\x1b[41m',

    grn_f : '\x1b[42m', // green
    gf    : '\x1b[42m',

    yel_f : '\x1b[43m', // yellow
    yf    : '\x1b[43m',

    blue_f: '\x1b[44m', // blue
    bf    : '\x1b[44m',

    prp_f : '\x1b[45m', // purple
    mf    : '\x1b[45m',

    trq_f : '\x1b[46m', // cyan
    cf    : '\x1b[46m',

    wht_f : '\x1b[47m', // white
    wf    : '\x1b[47m',
}

// returnsarray of strings without color tags
function decolorText(...text) {
    let replacer
    let res = []
    let txt
    for (let i = 0; i < text.length; i++) {
        txt = text[i].toString()
        for (let k in styles) {
            replacer = new RegExp(`<${k}>`, "g")
            txt = txt.replace(replacer, "")  
        }
        res.push(txt)
    }
    return res 
}

// returns array of strings with color keys as in styles
function colorText(...text) {
    let replacer
    let res = []
    let txt
    for (let i = 0; i < text.length; i++) {
        txt = text[i].toString()
        for (let k in styles) {
            replacer = new RegExp(`<${k}>`, "g")
            txt = txt.replace(replacer, styles[k])  
        }  
        txt = txt + styles["clr"]
        res.push(txt)
    }
    return res 
}

// prints color strings to console, returns decolored array of strings
function log(...text) {
    console.log(...colorText(...text))
    return decolorText(...text)
}

module.exports = {
    log,
    colorText,
    decolorText,
}


