#if defined(__AVR__)
int main() {
  return 0;
}

#else
#include <stdio.h>

int main() {
  printf("Hello world!\n");
  return 0;
}
#endif