#ifndef NORTINSTALL_FFI_H
#define NORTINSTALL_FFI_H

/* Разбирает Info.plist внутри IPA и возвращает JSON:
   {"name":"...","bundle_id":"...","version":"...","minimum_os":"..."}
   либо {"error":"..."}. Результат освобождается ni_free_string. */
char *ni_ipa_info(const char *path);

/* Освобождает строку, возвращённую ni_ipa_info. */
void ni_free_string(char *string);

#endif /* NORTINSTALL_FFI_H */
