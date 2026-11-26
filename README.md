# Pitwall — liga typowania F1

## Aktualizacja: zakończenie sezonu

W istniejącym projekcie Supabase uruchom raz plik `migration-finish-season.sql` w SQL Editorze, a następnie wgraj nowy `app.js` na GitHub Pages. Nie uruchamiaj ponownie `schema.sql` na istniejącej bazie. Przycisk w panelu administratora po potwierdzeniu zapisuje punktację i trwale usuwa wszystkie wyścigi i typowania, również przyszłe; konta i kierowcy pozostają. Punktacja z zakończonych sezonów jest widoczna na dole klasyfikacji.

## Aktualizacja: usuwanie wyścigów

W istniejącym projekcie Supabase uruchom zawartość pliku `migration-delete-race.sql` w SQL Editorze. Nie uruchamiaj ponownie całego `schema.sql` na istniejącej bazie. Następnie wgraj nowy `app.js` na GitHub Pages. W panelu administratora wybierz „Edytuj” przy wyścigu, a następnie „Usuń wyścig”. Po potwierdzeniu zostaną trwale usunięte także wyniki i typowania, a klasyfikacja zostanie przeliczona.

