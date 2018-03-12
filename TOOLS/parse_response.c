#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <expat.h>
#include "utstring.h"

#define BUFSIZE 102400

typedef enum {
  ArrayOfTranslateArrayResponse,
  TranslateArrayResponse, 
  From, 
  OriginalTextSentenceLengths,  
  State, 
  TranslatedText, 
  TranslatedTextSentenceLengths,
  OriginalTextSentenceLengthsValue,
  TranslatedTextSentenceLengthsValue
} element;

element current = ArrayOfTranslateArrayResponse;

static void XMLCALL
elementStart(void *user_data, const XML_Char *el, const XML_Char *attr[]) 
{
  switch (current) {
    case ArrayOfTranslateArrayResponse:
      if (strcmp(el,"TranslateArrayResponse") == 0)
        current = TranslateArrayResponse;
      break;
    case TranslateArrayResponse:
      if (strcmp(el,"From") == 0)
        current = From;
      else if (strcmp(el,"OriginalTextSentenceLengths") == 0)
        current = OriginalTextSentenceLengths;
      else if (strcmp(el,"State") == 0)
        current = State;
      else if (strcmp(el,"TranslatedText") == 0)
        current = TranslatedText;
      else if (strcmp(el,"TranslatedTextSentenceLengths") == 0)
        current = TranslatedTextSentenceLengths;
      break;
    case OriginalTextSentenceLengths:
      if (strcmp(el,"a:int") == 0) 
        current = OriginalTextSentenceLengthsValue;
      break;
    case TranslatedTextSentenceLengths:
      if (strcmp(el,"a:int") == 0) 
        current = TranslatedTextSentenceLengthsValue;
      break;
    case From:
    case State:
      break;
    default:
      current = ArrayOfTranslateArrayResponse;
      break;
  }
}

static void XMLCALL
elementEnd(void *user_data, const XML_Char *el) 
{
  switch (current) {
    case ArrayOfTranslateArrayResponse:
      break;
    case TranslateArrayResponse:
      current = ArrayOfTranslateArrayResponse;
      break;
    case From:
      current = TranslateArrayResponse;
      break;
    case OriginalTextSentenceLengths:
      current = TranslateArrayResponse;
      break;
    case State:
      current = TranslateArrayResponse;
      break;
    case TranslatedText:
      current = TranslateArrayResponse;
      break;
    case TranslatedTextSentenceLengths:
      current = TranslateArrayResponse;
      break;
    case OriginalTextSentenceLengthsValue:
      current = OriginalTextSentenceLengths;
      break;
    case TranslatedTextSentenceLengthsValue:
      current = TranslatedTextSentenceLengths;
      break;
    default:
      break;
  }
}

static void XMLCALL
elementData(void *user_data, const XML_Char *data, int data_size) 
{
  switch (current) {
    case From:
      printf("From ");
      break;
    case OriginalTextSentenceLengthsValue:
      printf("OriginalTextSentenceLengths ");
      break;
    case State:
      printf("State ");
      break;
    case TranslatedText:
      printf("TranslatedText ");
      break;
    case TranslatedTextSentenceLengthsValue:
      printf("TranslatedTextSentenceLengths ");
      break;
    default:
      return;
  } 

  UT_string *str = NULL;
  utstring_new(str);
  if (data_size != 0) {
    utstring_bincpy(str, data, data_size);
  } else {
    utstring_bincpy(str, "_", 1);
  }
  printf("%s\n", utstring_body(str));
  utstring_free(str);
}

int 
main(int argc, char *argv[]) {
  char buf[BUFSIZE];
  int done;
  XML_Parser parser;

  if ((parser = XML_ParserCreate(NULL)) == NULL) {
    fprintf(stderr, "Parser Creation Error.\n");
    exit(1);
  }

  XML_SetElementHandler(parser, elementStart, elementEnd);
  XML_SetCharacterDataHandler(parser, elementData);

  do {
    size_t len = fread(buf, sizeof(char), BUFSIZE, stdin);
    if (ferror(stdin)) {
      fprintf(stderr, "File Error.\n");
      exit(1);
    }

    done = len < sizeof(buf);
    if (XML_Parse(parser, buf, (int)len, done) == XML_STATUS_ERROR) {
      fprintf(stderr, "Parse Error.\n");
      exit(1);      
    }
  } while(!done);

  XML_ParserFree(parser);
  return(0);
}

