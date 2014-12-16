/* description: Compiles Bitcoin Script to JavaScript. */

%{
    var beautify = require('js-beautify').js_beautify;
    var base = require('./config.js').base;
%}

/* lexical grammar */
%lex

%%
\s+                          { /* skip whitespace */ }
(0x)?([0-9]|[A-F]|[a-f])+\b  { return 'DATA'; }
/* Constants */
"OP_0"                       { return 'OP_FUNCTION'; }
"OP_FALSE"                   { return 'OP_FUNCTION'; }
"OP_1NEGATE"                 { return 'OP_FUNCTION'; }
"OP_1"                       { return 'OP_FUNCTION'; }
"OP_TRUE"                    { return 'OP_FUNCTION'; }
OP_([2-9]|1[0-6])\b          { return 'DATA'; }
/* Flow control */
"OP_NOP"                     { return 'OP_NOP'; }
"OP_IF"                      { return 'OP_IF'; }
"OP_NOTIF"                   { return 'OP_NOTIF'; }
"OP_ELSE"                    { return 'OP_ELSE'; }
"OP_ENDIF"                   { return 'OP_ENDIF'; }
"OP_VERIFY"                  { return 'OP_TERMINAL'; }
"OP_RETURN"                  { return 'OP_TERMINAL'; }
"OP_EQUALVERIFY"             { return 'OP_TERMINAL'; }
"OP_CHECKSIGVERIFY"          { return 'OP_TERMINAL'; }
"OP_CHECKMULTISIGVERIFY"     { return 'OP_TERMINAL'; }
/* Stack */
"OP_IFDUP"                   { return 'OP_FUNCTION'; }
"OP_DEPTH"                   { return 'OP_FUNCTION'; }
"OP_DROP"                    { return 'OP_FUNCTION'; }
"OP_DUP"                     { return 'OP_FUNCTION'; }
"OP_NIP"                     { return 'OP_FUNCTION'; }
"OP_OVER"                    { return 'OP_FUNCTION'; }
"OP_PICK"                    { return 'OP_FUNCTION'; }
"OP_ROLL"                    { return 'OP_FUNCTION'; }
"OP_ROT"                     { return 'OP_FUNCTION'; }
"OP_SWAP"                    { return 'OP_FUNCTION'; }
"OP_TUCK"                    { return 'OP_FUNCTION'; }
"OP_2DROP"                   { return 'OP_FUNCTION'; }
"OP_2DUP"                    { return 'OP_FUNCTION'; }
"OP_3DUP"                    { return 'OP_FUNCTION'; }
"OP_2OVER"                   { return 'OP_FUNCTION'; }
"OP_2ROT"                    { return 'OP_FUNCTION'; }
"OP_2SWAP"                   { return 'OP_FUNCTION'; }
/* Bitwise logic */
"OP_EQUAL"                   { return 'OP_FUNCTION'; }
/* Arithmetic */
"OP_1ADD"                    { return 'OP_FUNCTION'; }
"OP_1SUB"                    { return 'OP_FUNCTION'; }
"OP_NEGATE"                  { return 'OP_FUNCTION'; }
"OP_ABS"                     { return 'OP_FUNCTION'; }
"OP_NOT"                     { return 'OP_FUNCTION'; }
"OP_0NOTEQUAL"               { return 'OP_FUNCTION'; }
"OP_ADD"                     { return 'OP_FUNCTION'; }
"OP_SUB"                     { return 'OP_FUNCTION'; }
"OP_BOOLAND"                 { return 'OP_FUNCTION'; }
"OP_BOOLOR"                  { return 'OP_FUNCTION'; }
"OP_NUMEQUAL"                { return 'OP_FUNCTION'; }
"OP_NUMNOTEQUAL"             { return 'OP_FUNCTION'; }
"OP_LESSTHAN"                { return 'OP_FUNCTION'; }
"OP_GREATERTHAN"             { return 'OP_FUNCTION'; }
"OP_LESSTHANOREQUAL"         { return 'OP_FUNCTION'; }
"OP_GREATERTHANOREQUAL"      { return 'OP_FUNCTION'; }
"OP_MIN"                     { return 'OP_FUNCTION'; }
"OP_MAX"                     { return 'OP_FUNCTION'; }
"OP_WITHIN"                  { return 'OP_FUNCTION'; }
/* Crypto */
"OP_RIPEMD160"               { return 'OP_FUNCTION'; }
"OP_SHA1"                    { return 'OP_FUNCTION'; }
"OP_SHA256"                  { return 'OP_FUNCTION'; }
"OP_HASH160"                 { return 'OP_FUNCTION'; }
"OP_HASH256"                 { return 'OP_FUNCTION'; }
"OP_CHECKSIG"                { return 'OP_FUNCTION'; }
"OP_CHECKMULTISIG"           { return 'OP_FUNCTION'; }
<<EOF>>                      { return 'EOF'; }

/lex

%nonassoc OP_ELSE
%nonassoc OP_ENDIF

%start expressions

%% /* language grammar */

expressions
    : nonterminal expressions
    | terminal EOF
        %{
            var js = beautify($1);
            var evaluate = new Function('stack', js);
            return {
                evaluate: evaluate,
                code: js
            };
        %}
    ;

terminal
    : OP_TERMINAL
        %{
            $$ = ($0 || '') + 'return stack.' + $1  + '();'
        %}
    ;

statement
    : nonterminal
    | nonterminal statement
    ;

nonterminal
    : DATA
        %{
            var value;
            if ($1.indexOf('OP_') !== -1) {
                // These statements encrypt their value as decimal, so convert
                value = parseInt($1.substr('OP_'.length)).toString(base);
            } else if ($1.indexOf('0x') !== -1) {
                // Otherwise, conversion takes place anyway when you push
                value = $1.substr('0x'.length);
            } else {
                value = $1;
            }
            $$ = ($0 || '') + 'stack.push("' + value + '");';
        %}
    | OP_IF statement OP_ELSE statement OP_ENDIF
        %{
            var b1 = $statement1.substr('OP_IF'.length);
            var b2 = $statement2.substr('OP_ELSE'.length);
            $$ = ($0 || '') + 'if (stack.pop().compare(0) !== 0) {' + b1 + '} else {' + b2 + '};';
        %}
    | OP_IF statement OP_ENDIF
        %{
            var b1 = $statement.substr('OP_IF'.length);
            $$ = ($0 || '') + 'if (stack.pop().compare(0) !== 0) {' + b1 + '};';
        %}
    | OP_NOTIF statement OP_ELSE statement OP_ENDIF
        %{
            var b1 = $statement1.substr('OP_NOTIF'.length);
            var b2 = $statement2.substr('OP_ELSE'.length);
            $$ = ($0 || '') + 'if (stack.pop().equals(0)) {' + b1 + '} else {' + b2 + '};';
        %}
    | OP_NOTIF statement OP_ENDIF
        %{
            var b1 = $statement.substr('OP_NOTIF'.length);
            $$ = ($0 || '') + 'if (stack.pop().equals(0)) {' + b1 + '};';
        %}
    | OP_NOP
        %{
            $$ = ($0 || '');
        %}
    | OP_FUNCTION
        %{
            $$ = ($0 || '') + 'stack.' + $1  + '();'
        %}
    ;