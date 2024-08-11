

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mysql.h>

my_bool pagetolimits_udf_init(UDF_INIT *initid, UDF_ARGS *args, char *message);
void pagetolimits_udf_deinit(UDF_INIT *initid);
char *pagetolimits_udf(UDF_INIT *initid, UDF_ARGS *args, char *result, unsigned long *length, char *is_null, char *error);

my_bool pagetolimits_udf_init(UDF_INIT *initid, UDF_ARGS *args, char *message)
{
  if (args->arg_count != 1 || args->arg_type[0] != STRING_RESULT)
  {
    strcpy(message, "Expected one string argument");
    return 1;
  }
  
  initid->max_length = 128;
  return 0;
}

void pagetolimits_udf_deinit(UDF_INIT *initid)
{
  // Nothing to do here
}

char *pagetolimits_udf(UDF_INIT *initid, UDF_ARGS *args, char *result, unsigned long *length, char *is_null, char *error)
{
  long long page;
  sscanf(args->args[0], "%lld", &page);

  long long offset = (page - 1) * 45;
  long long range = 45;

  double *arr = malloc(sizeof(double) * 2);
  arr[0] = offset;
  arr[1] = range;

  *length = sizeof(double) * 2;
  memcpy(result, arr, *length);

  free(arr);
  return result;
}