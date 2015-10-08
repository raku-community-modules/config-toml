use v6;
unit grammar Config::TOML::Parser::Grammar;

# disposable grammar {{{

proto token gap {*}
token gap:spacer { \s }
token gap:comment { <.comment> \n }

# end disposable grammar }}}
# comment grammar {{{

token comment
{
    '#' <comment_text>
}

token comment_text
{
    \N*
}

# end comment grammar }}}
# string grammar {{{

token string
{
    <string_basic_multiline>
    | <string_basic>
    | <string_literal_multiline>
    | <string_literal>
}

# --- string basic grammar {{{

token string_basic
{
    '"' <string_basic_text>? '"'
}

token string_basic_text
{
    <string_basic_char>+
}

proto token string_basic_char {*}

token string_basic_char:common
{
    # anything but linebreaks, double-quotes, backslashes and control
    # characters (U+0000 to U+001F)
    <+[\N] -[\" \\] -[\x00..\x1F]>
}

token string_basic_char:tab
{
    \t
}

token string_basic_char:escape_sequence
{
    # backslash followed by a valid TOML escape code, or error
    \\
    [
        <escape>

        ||

        .
        {
            say "Sorry, found bad TOML escape sequence 「$/」";
            exit;
        }
    ]
}

# For convenience, some popular characters have a compact escape sequence.
#
# \b         - backspace       (U+0008)
# \t         - tab             (U+0009)
# \n         - linefeed        (U+000A)
# \f         - form feed       (U+000C)
# \r         - carriage return (U+000D)
# \"         - quote           (U+0022)
# \\         - backslash       (U+005C)
# \uXXXX     - unicode         (U+XXXX)
# \UXXXXXXXX - unicode         (U+XXXXXXXX)
proto token escape {*}
token escape:sym<b> { <sym> }
token escape:sym<t> { <sym> }
token escape:sym<n> { <sym> }
token escape:sym<f> { <sym> }
token escape:sym<r> { <sym> }
token escape:sym<quote> { \" }
token escape:sym<backslash> { \\ }
token escape:sym<u> { <sym> <hex> ** 4 }
token escape:sym<U> { <sym> <hex> ** 8 }

token hex
{
    <[0..9A..F]>
}

token string_basic_multiline
{
    <string_basic_multiline_delimiter>
    <string_basic_multiline_leading_newline>?
    <string_basic_multiline_text>?
    <string_basic_multiline_delimiter>
}

token string_basic_multiline_delimiter
{
    '"""'
}

token string_basic_multiline_leading_newline
{
    # A newline immediately following the opening delimiter will be
    # trimmed.
    \n
}

token string_basic_multiline_text
{
    <string_basic_multiline_char>+
}

proto token string_basic_multiline_char {*}

token string_basic_multiline_char:common
{
    # anything but delimiters ("""), backslashes and control characters
    # (U+0000 to U+001F)
    <-string_basic_multiline_delimiter -[\\] -[\x00..\x1F]>
}

token string_basic_multiline_char:tab
{
    \t
}

token string_basic_multiline_char:newline
{
    \n+
}

token string_basic_multiline_char:escape_sequence
{
    # backslash followed by either a valid TOML escape code or linebreak,
    # else error
    \\
    [
        [
            <escape> | $$ <ws_remover>
        ]

        ||

        .
        {
            say "Sorry, found bad TOML escape sequence 「$/」";
            exit;
        }
    ]
}

token ws_remover
{
    # For writing long strings without introducing extraneous whitespace,
    # end a line with a \. The \ will be trimmed along with all whitespace
    # (including newlines) up to the next non-whitespace character or
    # closing delimiter.
    \n+\s*
}

# --- end string basic grammar }}}
# --- string literal grammar {{{

token string_literal
{
    \' <string_literal_text>? \'
}

token string_literal_text
{
    <string_literal_char>+
}

proto token string_literal_char {*}

token string_literal_char:common
{
    # anything but linebreaks and single quotes
    # Since there is no escaping, there is no way to write a single
    # quote inside a literal string enclosed by single quotes.
    <+[\N] -[\']>
}

token string_literal_char:backslash
{
    \\
}

token string_literal_multiline
{
    <string_literal_multiline_delimiter>
    <string_literal_multiline_leading_newline>?
    <string_literal_multiline_text>?
    <string_literal_multiline_delimiter>
}

token string_literal_multiline_delimiter
{
    \'\'\'
}

token string_literal_multiline_leading_newline
{
    # A newline immediately following the opening delimiter will be
    # trimmed.
    \n
}

token string_literal_multiline_text
{
    <string_literal_multiline_char>+
}

proto token string_literal_multiline_char {*}

token string_literal_multiline_char:common
{
    # anything but delimiters (''') and backslashes
    <-string_literal_multiline_delimiter -[\\]>
}

token string_literal_multiline_char:backslash
{
    \\
}

# --- end string literal grammar }}}

# end string grammar }}}
# number grammar {{{

token number
{
    <float> | <integer>
}

token integer
{
    <plus_or_minus>? <whole_number>
}

proto token plus_or_minus {*}
token plus_or_minus:sym<+> { <sym> }
token plus_or_minus:sym<-> { <sym> }

token whole_number
{
    0

    |

    # Leading zeros are not allowed.
    <[1..9]> [ '_'? <.digits> ]?
}

token digits
{
    \d+

    |

    # For large numbers, you may use underscores to enhance
    # readability. Each underscore must be surrounded by at least
    # one digit.
    \d+ '_' <.digits>
}

token float
{
    <integer_part=.integer>
    [
        '.' <fractional_part=.digits> <exponent_part>?
        | <exponent_part>
    ]
}

token exponent_part
{
    <[Ee]> <integer_part=.integer>
}

# end number grammar }}}
# boolean grammar {{{

# Booleans are just the tokens you're used to. Always lowercase.
proto token boolean {*}
token boolean:sym<true> { <sym> }
token boolean:sym<false> { <sym> }

# end boolean grammar }}}
# datetime grammar {{{

# Datetimes are RFC 3339 dates: http://tools.ietf.org/html/rfc3339

token date_fullyear
{
    \d ** 4
}

token date_month
{
    0 <[1..9]> | 1 <[0..2]>
}

token date_mday
{
    0 <[1..9]> | <[1..2]> \d | 3 <[0..1]>
}

token time_hour
{
    <[0..1]> \d | 2 <[0..3]>
}

token time_minute
{
    <[0..5]> \d
}

token time_second
{
    # The grammar element time-second may have the value "60" at the end
    # of months in which a leap second occurs.
    <[0..5]> \d | 60
}

token time_secfrac
{
    '.' \d+
}

token time_numoffset
{
    <plus_or_minus> <time_hour> ':' <time_minute>
}

token time_offset
{
    <[Zz]> | <time_numoffset>
}

token partial_time
{
    <time_hour> ':' <time_minute> ':' <time_second> <time_secfrac>?
}

token full_date
{
    <date_fullyear> '-' <date_month> '-' <date_mday>
}

token full_time
{
    <partial_time> <time_offset>
}

token date_time
{
    <full_date> <[Tt]> <full_time>
}

# end datetime grammar }}}
# array grammar {{{

token array
{
    '['
    <.gap>*
    [ <array_elements> <.gap>* ','? ]?
    <.gap>*
    ']'
}

proto token array_elements {*}

token array_elements:strings
{
    <string>
    [
        <.gap>* ',' <.gap>*
        <string>
    ]*
}

token array_elements:integers
{
    <integer>
    [
        <.gap>* ',' <.gap>*
        <integer>
    ]*
}

token array_elements:floats
{
    <float>
    [
        <.gap>* ',' <.gap>*
        <float>
    ]*
}

token array_elements:booleans
{
    <boolean>
    [
        <.gap>* ',' <.gap>*
        <boolean>
    ]*
}

token array_elements:date_times
{
    <date_time>
    [
        <.gap>* ',' <.gap>*
        <date_time>
    ]*
}

token array_elements:arrays
{
    <array>
    [
        <.gap>* ',' <.gap>*
        <array>
    ]*
}

token array_elements:table_inlines
{
    <table_inline>
    [
        <.gap>* ',' <.gap>*
        <table_inline>
    ]*
}

# end array grammar }}}
# table grammar {{{

token table_inline
{
    '{'
    <.gap>*
    [ <table_inline_keypairs> <.gap>* ','? ]?
    <.gap>*
    '}'
    {
        # verify inline table does not contain duplicate keys
        if $<table_inline_keypairs>.made
        {
            my Str @keys_seen;
            push @keys_seen, $_ for $<table_inline_keypairs>.made».keys.flat;
            unless @keys_seen.elems == @keys_seen.unique.elems
            {
                helpmsg_duplicate_keys($/.orig.Str, @keys_seen);
                exit;
            }
        }
    }
}

token table_inline_keypairs
{
    <keypair>
    [
        <.gap>* ',' <.gap>*
        <keypair>
    ]*
}

token keypair
{
    <keypair_key> \h* '=' \h* <keypair_value>
}

proto token keypair_key {*}

token keypair_key:bare
{
    <+alnum +[-]>+
}

token keypair_key:quoted
{
    <string_basic>
}

proto token keypair_value {*}
token keypair_value:string { <string> }
token keypair_value:number { <number> }
token keypair_value:boolean { <boolean> }
token keypair_value:date_time { <date_time> }
token keypair_value:array { <array> }
token keypair_value:table_inline { <table_inline> }

proto token table {*}

# standard TOML table (with keypairs stored in type: Hash)
token table:hash
{
    ^^ \h* <hashtable_header> \h* <.comment>? $$ \n
    [ <keypair_line> | <.comment_line> | <.blank_line> ]*
}

# TOML array of tables (with keypairs stored in type: Array[Hash])
token table:array
{
    ^^ \h* <arraytable_header> \h* <.comment>? $$ \n
    [ <keypair_line> | <.comment_line> | <.blank_line> ]*
}

token hashtable_header
{
    '[' \h* <table_header_text> \h* ']'
}

token arraytable_header
{
    '[[' \h* <table_header_text> \h* ']]'
}

token table_header_text
{
    <keypair_key> [ \h* '.' \h* <keypair_key> ]*
}

# end table grammar }}}
# document grammar {{{

# blank line
token blank_line
{
    ^^ \h* $$ \n
}

# comment appearing on its own line
token comment_line
{
    ^^ \h* <.comment> $$ \n
}

# keypair appearing on its own line
token keypair_line
{
    ^^ \h* <keypair> \h* <.comment>? $$ \n
}

proto token segment {*}

token segment:blank_line
{
    <blank_line>
}

token segment:comment_line
{
    <comment_line>
}

token segment:keypair_line
{
    <keypair_line>
}

token segment:table
{
    <table>
}

token TOP
{
    <segment>*
}

# end document grammar }}}

# helper functions {{{

sub helpmsg_duplicate_keys(Str:D $table_inline_orig, Str:D @keys_seen)
{
    say "Sorry, inline table contains duplicate keys.";
    say "------------------------------------------------------------------------";
    say "Inline table:";
    say $table_inline_orig;
    say "------------------------------------------------------------------------";
    say "Keys seen:";
    .say for @keys_seen.sort».subst(
        /(.*)/,
        -> $/
        {
            state Int $i = 1;
            my Str $replacement = "$i.「$0」";
            $i++;
            $replacement;
        }
    );
    say "------------------------------------------------------------------------";
    say "Keys seen (unique):";
    .say for @keys_seen.unique.sort».subst(
        /(.*)/,
        -> $/
        {
            state Int $i = 1;
            my Str $replacement = "$i.「$0」";
            $i++;
            $replacement;
        }
    );
}

# end helper functions }}}

# vim: ft=perl6 fdm=marker fdl=0
