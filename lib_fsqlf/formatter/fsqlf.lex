/*
Thanks to http://vsbabu.org/software/lsqlb.html
Vattekkat Satheesh Babu, on Dec 30, 1998
Helped to learn about flex a bit
*/

%top{
// This code goes at the "top" of the generated file.
// Also it gets into generated header file.
#include <stdio.h>      // fprintf, stdin, stdout
#include "tokque.h"     // FSQLF_tokque_putthrough
#include "../../utils/stack/stack.h" // struct FSQLF_stack


typedef struct
{
    int left;
    int right;
} pair;


struct fsqlf_formatter_state
{
    // Global indent. (e.g. for subqueries and case expressions)
    int currindent;

    // Count of left and right paranthesis.
    int left_p;
    int right_p;

    // Lex state (start condition) stack.
    struct FSQLF_stack lexstate_stack;

    // Pairs of paranthesis stored at each start of subquery.
    struct FSQLF_stack sub_openings;

    // Configuration of all keywords.
    struct fsqlf_kw_conf *kwall;

    // Queue used for processing tokens.
    struct FSQLF_queue tqueue;

    // Output buffer.
    struct FSQLF_out_buffer bout;
};

}


%{
// This does not get into generated header file.

#define BEGIN_STATE(NEWSTATE) BEGIN(NEWSTATE);

#define PUSH_STATE(NEWSTATE) \
do { \
    FSQLF_stack_push(&yyextra->lexstate_stack, &(int){YY_START}); \
    BEGIN_STATE(NEWSTATE); \
} while (0)

#define POP_STATE() \
do { \
    BEGIN_STATE(*(int*)FSQLF_stack_peek(&yyextra->lexstate_stack)); \
    FSQLF_stack_pop(&yyextra->lexstate_stack); \
} while (0)

// Use KW with ability to change state.
#define TUSE_W_STATES(TKW) \
do { \
    struct FSQLF_state_change sc = FSQLF_tokque_putthrough( \
        &yyextra->tqueue, \
        yyout, &yyextra->bout, \
        &yyextra->currindent, yytext, yyleng, TKW, YY_START \
    ); \
    if (sc.state_change_action == FSQLF_SCA_BEGIN) { \
        BEGIN(sc.new_state); \
    } \
} while (0)

// Use KW without ability to change state.
#define TUSE_SIMPLE(TKW) \
do { \
    FSQLF_tokque_putthrough( \
        &yyextra->tqueue, \
        yyout, &yyextra->bout, \
        &yyextra->currindent, yytext, yyleng, TKW, YY_START \
    ); \
} while (0)

%}


DIGIT   [0-9]
NUMBER  {DIGIT}+([.]{DIGIT}+)?([eE][+-]?{DIGIT}+)?
ID      [A-Za-z_][A-Za-z0-9_]*
SPACE   [ \t\n]
DBOBJECT    ({ID}[.]){0,2}{ID}


LEFTP   [(]
RIGHTP  [)]

UNION     (?i:union)
UNION_ALL (?i:union{SPACE}+all)
INTERSECT (?i:intersect)
EXCEPT    (?i:except)
LIMIT     (?i:limit)
MINUS     (?i:minus)
DIFFERENCE (?i:difference)

TABLE_OPT (?i:global|volatile|set|multiset|temporary)
CREATE  (?i:create)
DROP    (?i:drop)
TABLE   (?i:table)
VIEW    (?i:view)
IFEXISTS (?i:if{SPACE}+exists)
SELECT  (?i:select|sel)
AS      (?i:as)
FROM    (?i:from)
USING   (?i:using)
USING_INDEX   (?i:using{SPACE}+index)
USING_INDEX_NONE   (?i:using{SPACE}+index{SPACE}+none)
USE_INDEX   (?i:use{SPACE}+index)
FORCE_INDEX   (?i:force{SPACE}+index)
IGNORE_INDEX   (?i:ignore{SPACE}+index)

IJOIN   (?i:(inner{SPACE}+)?JOIN)
LJOIN   (?i:left{SPACE}+(OUTER{SPACE}+)?JOIN)
RJOIN   (?i:right{SPACE}+(OUTER{SPACE}+)?JOIN)
FJOIN   (?i:full{SPACE}+(OUTER{SPACE}+)?JOIN)
CJOIN   (?i:cross{SPACE}+JOIN{SPACE}+)
ANYJOIN ({LJOIN}|{RJOIN}|{FJOIN}|{CJOIN})

ON      (?i:on)
WHERE   (?i:where)
SAMPLE  (?i:sample)
AND     (?i:and)
OR      (?i:or)
NOT     (?i:not)
EXISTS  (?i:exists)
IN      (?i:in)
LIKE    (?i:like)

GROUPBY (?i:group{SPACE}+by)
ORDERBY (?i:order{SPACE}+by)
HAVING  (?i:having)
QUALIFY (?i:qualify)

COMMA [,]
COMP_EQ (=)
COMP_NE (<>)
COMP_LE (<=)
COMP_GE (>=)
COMP_LT (<)
COMP_GT (>)

COMMENT_ONE_LINE [-]{2,}[^\n]*[\n]?
COMMENT_ML [/][*]([^*]|[*]+[^*/])*[*]+[/]

STRING ([xX]?['][^'']*['])+
SEMICOLON ;
OP_PLUS   (\+)
OP_MINUS  (-)
OP_MULT   (\*)
OP_DIV    (\/)
OP_CONCAT (\|\|)


INSERTINTO (?i:(ins|insert){SPACE}+into)
UPDATE (?i:upd|update)
SET (?i:set)
DELETEFROM (?i:(del|delete){SPACE}+from)
DELETE (?i:(del|delete))

CASE (?i:case)
WHEN (?i:when)
THEN (?i:then)
ELSE (?i:else)
END (?i:end)


%option reentrant
%option extra-type="struct fsqlf_formatter_state *"
%option noyywrap
%option nounput
%option noinput
/* always-interactive - removes usage of fileno, isatty (not C99 compliant).
 * See details at:
 *     http://flex.sourceforge.net/manual/Why-do-flex-scanners-call-fileno-if-it-is-not-ANSI-compatible_003f.html
 */
%option always-interactive

%s stSELECT stFROM stWHERE stON stEXISTS stLEFTP stJOIN stIN stCOMMA stINLIST stFROM_LEFTP stP_SUB stORDERBY stGROUPBY stINSERT stINSCOLLIST stUPDATE stSET stDELETE stIN_CONSTLIST stCREATE stTAB_COL_LIST

%%

{DELETEFROM}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_deletefrom")); }
{DELETE}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_delete")); }
{UPDATE}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_update")); }
{SET} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_set")); }
<stSET>{COMMA} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_set")); }

{DROP}       { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_drop")); }
{IFEXISTS}   { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_ifexists")); }
{USING} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_using")); }
{USING_INDEX} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_using_index")); }
{USING_INDEX_NONE} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_using_index_none")); }
{USE_INDEX} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_use_index")); }
{FORCE_INDEX} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_force_index")); }
{IGNORE_INDEX} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_ignore_index")); }
{TABLE}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_table")); }
{VIEW}       { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_view")); }

                /* SET operations */
{UNION}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_union")); }
{UNION_ALL}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_union_all")); }
{MINUS}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_minus")); }
{DIFFERENCE} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_difference")); }
{INTERSECT}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_intersect")); }
{EXCEPT}     { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_except")); }
{LIMIT}      { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_limit")); }

                /* comparison and arithmetic operators */
{IN}    { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_in")); }
{LIKE}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_like")); };
{COMP_EQ}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_eq")); };
{COMP_NE}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_ne")); };
{COMP_LE}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_le")); };
{COMP_GE}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_ge")); };
{COMP_LT}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_lt")); };
{COMP_GT}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comp_gt")); };
{NOT}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_not")); };
{EXISTS} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_exists")); };

                /* SELECT ... FROM */
<INITIAL,stINSERT>{SELECT}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_select")); };
<stSELECT,stCOMMA>{COMMA}   { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_comma")); };

<stLEFTP>{LEFTP}            { PUSH_STATE(stLEFTP); TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_left_p")); yyextra->left_p++; };
<stLEFTP>{COMMA}            { TUSE_SIMPLE(NULL); };
<stLEFTP>{ORDERBY}          { TUSE_SIMPLE(NULL); };
<stLEFTP>{FROM}             { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_from_2"));  };
<stLEFTP>{RIGHTP}           { POP_STATE(); TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p")); yyextra->right_p++; };
{FROM} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_from")); };
<stLEFTP,stSELECT>{AS}      { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_as")); };

                /* FROM ... JOIN ... ON ... WHERE ...*/
{IJOIN} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_inner_join")); };
{LJOIN} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_left_join")); };
{RJOIN} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_right_join")); };
{FJOIN} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_full_join")); };
{CJOIN} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_cross_join")); };
<stON,stFROM,stJOIN>{COMMA} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_join")); };
<stJOIN>{ON} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_on")); };
{WHERE} { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_where")); };
<stWHERE,stON,stJOIN>{AND}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_and"));   };
<stWHERE,stON,stJOIN>{OR}   { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_or"));    };

                /* GROUPBY .. ORDER BY ... HAVING .. QUALIFY */
{GROUPBY}    { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_groupby")); }
{ORDERBY}    { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_orderby")); }
<stORDERBY>{COMMA}   { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_ordby")); };
<stGROUPBY>{COMMA}   { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_grpby")); };
{HAVING}     { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_having")); }
{QUALIFY}    { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_qualify")); }

{INSERTINTO}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_insertinto")); }
<stINSERT>{LEFTP}        { PUSH_STATE(stINSCOLLIST); TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_left_p_ins")); };
<stINSCOLLIST>{COMMA}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_ins")); }
<stINSCOLLIST>{RIGHTP}   { POP_STATE();              TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p_ins")); };

{CREATE}     { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_create")); }
<stCREATE>{LEFTP}  { PUSH_STATE(stTAB_COL_LIST); TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_left_p_create")); };
<stTAB_COL_LIST>{COMMA}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comma_create")); }
<stTAB_COL_LIST>{RIGHTP}   { POP_STATE();              TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p_create")); };

                /* possible subselect */
<stP_SUB>{LEFTP} {
        BEGIN_STATE(*(int*)FSQLF_stack_peek(&yyextra->lexstate_stack));
        TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_left_p"));
        yyextra->left_p++;
        PUSH_STATE(stP_SUB);  
    };
{LEFTP} { PUSH_STATE(stP_SUB); };
<stP_SUB>{CASE} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_case"));};
<stP_SUB>{SELECT} {
        BEGIN_STATE(stSELECT);
        FSQLF_tokque_putthrough(&yyextra->tqueue, yyout, &yyextra->bout, &yyextra->currindent, "(", 1, fsqlf_kw_get(yyextra->kwall, "kw_left_p_sub"), YY_START);
        FSQLF_stack_push(&yyextra->sub_openings, &(pair){yyextra->left_p, yyextra->right_p}); // begin sub
        yyextra->currindent++; // begin sub
        TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_select"));
    };
<stP_SUB>{NUMBER}|{STRING}|{DBOBJECT} {
        if (*(int*)FSQLF_stack_peek(&yyextra->lexstate_stack) == stFROM
                || *(int*)FSQLF_stack_peek(&yyextra->lexstate_stack) == stJOIN) {
            BEGIN_STATE(*(int*)FSQLF_stack_peek(&yyextra->lexstate_stack));
            FSQLF_tokque_putthrough(&yyextra->tqueue, yyout, &yyextra->bout, &yyextra->currindent, "(", 1, fsqlf_kw_get(yyextra->kwall, "kw_left_p"), YY_START);
            yyextra->left_p++;
            TUSE_SIMPLE(NULL);
        } else {
            BEGIN_STATE(stIN_CONSTLIST);
            FSQLF_tokque_putthrough(&yyextra->tqueue, yyout, &yyextra->bout, &yyextra->currindent, "(", 1, fsqlf_kw_get(yyextra->kwall, "kw_left_p"), YY_START);
            yyextra->left_p++;
            TUSE_SIMPLE(NULL);
        }
    };
<stP_SUB>{COMMENT_ML} { TUSE_SIMPLE(NULL); };
<stP_SUB>{COMMENT_ONE_LINE} { TUSE_SIMPLE(NULL); };
<stP_SUB>{SPACE}            { };
<stP_SUB>{RIGHTP} {
        FSQLF_tokque_putthrough(&yyextra->tqueue, yyout, &yyextra->bout, &yyextra->currindent, "(", 1, fsqlf_kw_get(yyextra->kwall, "kw_left_p"), YY_START);
        yyextra->left_p++;
        POP_STATE();
        TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p"));
        yyextra->right_p++;
    };
<stP_SUB>. {
        BEGIN_STATE(*(int*)FSQLF_stack_peek(&yyextra->lexstate_stack));
        FSQLF_tokque_putthrough(&yyextra->tqueue, yyout, &yyextra->bout, &yyextra->currindent, "(", 1, fsqlf_kw_get(yyextra->kwall, "kw_left_p"), YY_START);
        yyextra->left_p++;
        TUSE_SIMPLE(NULL);
    };

{RIGHTP} {
        POP_STATE();
        if (!FSQLF_stack_empty(&yyextra->sub_openings) &&
            yyextra->left_p
                - (*(pair*)FSQLF_stack_peek(&yyextra->sub_openings)).left
                ==
                (yyextra->right_p+1)
                - (*(pair*)FSQLF_stack_peek(&yyextra->sub_openings)).right
                - 1) {
            FSQLF_stack_pop(&yyextra->sub_openings); // end sub
            yyextra->currindent--; // end sub
            TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p_sub"));
        } else {
            TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_right_p"));
            yyextra->right_p++;
        }

    };

{CASE}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_case")); }
{WHEN}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_when")); }
{THEN}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_then")); }
{ELSE}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_else")); }
{END}   { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_end")); }

{COMMENT_ML} { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_comments")); }
{COMMENT_ONE_LINE} { TUSE_SIMPLE(NULL);};

{STRING}     { TUSE_SIMPLE(NULL); }
{SPACE}+     { /* discard spaces */; }
{DBOBJECT}   { TUSE_SIMPLE(NULL); }
{NUMBER}     { TUSE_SIMPLE(NULL); }
{SEMICOLON}  { TUSE_W_STATES(fsqlf_kw_get(yyextra->kwall, "kw_semicolon")); }
{OP_PLUS}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_op_plus")); };
{OP_MINUS}   { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_op_minus")); };
{OP_MULT}    { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_op_mult")); };
{OP_DIV}     { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_op_div")); };
{OP_CONCAT}  { TUSE_SIMPLE(fsqlf_kw_get(yyextra->kwall, "kw_op_concat")); };
<*>.         { TUSE_SIMPLE(NULL); }


<<EOF>> {
        FSQLF_tokque_finish_out(&yyextra->tqueue, yyout, &yyextra->bout);
        fprintf(yyout, "\n");
        return 0;
    }

%%
