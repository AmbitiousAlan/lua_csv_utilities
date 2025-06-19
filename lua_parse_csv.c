#include <stdio.h>
#include <stdbool.h>
#include <ctype.h>
#include <string.h>

typedef enum {
    CSV_TOKEN_VALUE,
    CSV_TOKEN_COMMA,
    CSV_TOKEN_NEWLINE,
    CSV_TOKEN_END,
    CSV_TOKEN_ERROR
} CsvTokenType;

typedef struct {
    CsvTokenType type;
    const char* start;
    const char* end;
} CsvToken;

CsvToken csv_next_token(const char* csv, const char** cursor, char csv_delimiter) {
    const char* p = *cursor;
    CsvToken token;

    // Skip whitespace (optional, depends on your use case)
    while (*p == ' ' || *p == '\t') p++;

    token.start = p;

    if (*p == '\0') {
        token.type = CSV_TOKEN_END;
        token.end = p;
    } else if (*p == csv_delimiter) {
        token.type = CSV_TOKEN_COMMA;
        token.end = p + 1;
        p++;
    } else if (*p == '\r' || *p == '\n') {
        token.type = CSV_TOKEN_NEWLINE;
        if (*p == '\r' && *(p + 1) == '\n') p++; // handle CRLF
        token.end = p + 1;
        p++;
    } else {
        if (*p == '"') {
            p++;
            token.start = p;
            while (*p && (*p != '"' || (*(p + 1) == '"'))) {
                if (*p == '"' && *(p + 1) == '"') p++; // skip escaped quote
                p++;
            }
            token.end = p;
            if (*p == '"') p++; // closing quote
        } else {
            while (*p && *p != csv_delimiter && *p != '\r' && *p != '\n') {
                p++;
            }
            token.end = p;
        }
        token.type = CSV_TOKEN_VALUE;
    }

    *cursor = p;
    return token;
}

#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>


static void push_unescaped_string(lua_State *L, const char* start, size_t len) {
    char* buffer = malloc(len + 1); // max size needed
    if (!buffer) return; // handle error appropriately

    const char* src = start;
    char* dst = buffer;

    while (src < start + len) {
        if (src + 1 < start + len && src[0] == '"' && src[1] == '"') {
            *dst++ = '"'; // replace `""` with `"`, skip one
            src += 2;
        } else {
            *dst++ = *src++;
        }
    }

    lua_pushlstring(L, buffer, dst - buffer);
    free(buffer);
}

int lua_parse_csv(lua_State* L) {
    const char* csv = luaL_checkstring(L, 1);
    const char* cursor = csv;
    CsvToken token;

    lua_newtable(L); // outer table: rows
    int row_index = 1;

    lua_newtable(L); // current row
    int col_index = 1;

    while (1) {
        token = csv_next_token(csv, &cursor, ',');

        if (token.type == CSV_TOKEN_END) {
            lua_rawseti(L, -2, row_index++);
            break;
        }

        if (token.type == CSV_TOKEN_VALUE) {
            push_unescaped_string(L, token.start, token.end - token.start);
            lua_rawseti(L, -2, col_index);
        } else if (token.type == CSV_TOKEN_COMMA) {
            col_index++;
        } else if (token.type == CSV_TOKEN_NEWLINE) {
            lua_rawseti(L, -2, row_index++);
            lua_newtable(L);
            col_index = 1;
        }
    }

    return 1; // one return value: the table
}

int luaopen_parse_csv(lua_State* L) {
    lua_pushcfunction(L, lua_parse_csv);
    return 1; // return the function
}


