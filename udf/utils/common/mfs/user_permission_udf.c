#include <string.h>
#include <stdio.h>
#include <mysql.h>

#define STRING_SIZE 1024


static char *user_permission_init(MYSQL_THD thd, struct st_udf_init *initid, UDF_ARGS *args, char *message);
static longlong user_permission(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error);

my_bool user_permission_plugin_init(MYSQL_THD thd, UDF_INIT *initid) {
    return 0;
}

void user_permission_plugin_deinit(UDF_INIT *initid) {
    return;
}

static char *user_permission_init(MYSQL_THD thd, struct st_udf_init *initid, UDF_ARGS *args, char *message) {
    if (args->arg_count != 2) {
        strcpy(message, "user_permission(): Requires exactly 2 arguments");
        return message;
    }
    if (args->arg_type[0] != STRING_RESULT || args->arg_type[1] != STRING_RESULT) {
        strcpy(message, "user_permission(): Requires string arguments");
        return message;
    }
    return NULL;
}

static longlong user_permission(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error) {
    char *uid = args->args[0];
    char *rid = args->args[1];
    unsigned long uid_len = args->lengths[0];
    unsigned long rid_len = args->lengths[1];

    longlong perm = 0;
    char query[1024];

    MYSQL *mysql = mysql_init(NULL);
    mysql_real_connect(mysql, "localhost", "user", "password", NULL, 0, NULL, 0);

    char category[61];
    sprintf(query, "SELECT category FROM media WHERE id='%s'", rid_str);
    mysql_query(mysql, query);
    MYSQL_RES *result = mysql_store_result(mysql);
    MYSQL_ROW row = mysql_fetch_row(result);
    if (row != NULL) {
        strncpy(category, row[0], 60);
    }
    mysql_free_result(result);

    char uid_str[uid_len + 1];
    char rid_str[rid_len + 1];
    strncpy(uid_str, uid, uid_len);
    uid_str[uid_len] = '\0';
    if (strcmp(uid_str, "*") == 0 || strcmp(uid_str, "ffffffffffffffff") == 0 || strcmp(uid_str, "nobody") == 0) {
        strcpy(uid_str, "*");
    }

    if (strcmp(category, "hub") == 0) {
        sprintf(query, "SELECT permission FROM permission WHERE resource_id='%s' AND entity_id='%s'", rid_str, uid_str);
        mysql_query(mysql, query);
        result = mysql_store_result(mysql);
        row = mysql_fetch_row(result);
        if (row != NULL) {
            perm = atol(row[0]);
        }
        mysql_free_result(result);
    } else {
        sprintf(query, "SELECT IFNULL(permission, 0) FROM permission WHERE (entity_id='%s' AND '%s' != '*' AND resource_id='*') ORDER BY permission DESC LIMIT 1", uid_str, uid_str);
        mysql_query(mysql, query);
        result = mysql_store_result(mysql);
        row = mysql_fetch_row(result);
        if (row != NULL) {
            perm = atol(row[0]);
        }
        mysql_free_result(result);

        if (perm) {
            return perm;
        } else {
            sprintf(query, 
            "SELECT IFNULL(permission, 0) FROM permission WHERE (entity_id IN ('%s', '*', 'ffffffffffffffff', 'nobody')) AND resource_id='%s' ORDER BY permission DESC LIMIT 1", 
            uid_str, rid_str);
        }
        mysql_query(mysql, query);
        result = mysql_store_result(mysql);
        row = mysql_fetch_row(result);
        if (row != NULL) {
            perm = atol(row[0]);
        }
        mysql_free_result(result);

        if (perm) {
            return perm;
        } else {
            sprintf(query, 
            "SELECT IFNULL(parent_permission('%s', '%s'), 0)", 
            uid_str, rid_str);
        }

    }




