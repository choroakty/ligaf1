# Pitwall — liga typowania F1

Statyczna aplikacja na GitHub Pages z bazą PostgreSQL i logowaniem Supabase. Jest przeznaczona dla Piotra, Mateusza, Kacpra i osobnego administratora. Nie ma publicznej rejestracji.

## Uruchomienie

1. Utwórz projekt Supabase. W SQL Editor wykonaj cały plik `schema.sql` **raz**, na nowym projekcie. Zawiera on przykładową listę kierowców: przed użyciem administrator powinien ją przejrzeć i dostosować do aktualnego sezonu.
2. W Authentication wyłącz publiczną rejestrację (Allow new users to sign up). W Authentication → Users utwórz ręcznie cztery konta, potwierdzając adresy e-mail. To wewnętrzne identyfikatory, nie są potrzebne prawdziwe skrzynki:

   | Login w aplikacji | E-mail w Supabase | Hasło wpisywane przy tworzeniu konta w Supabase |
   | --- | --- | --- |
   | Piotr | piotr@pitwall.invalid | `2137:pitwall-f1` |
   | Mateusz | mateusz@pitwall.invalid | `2137:pitwall-f1` |
   | Kacper | kacper@pitwall.invalid | `2137:pitwall-f1` |
   | Admin | admin@pitwall.invalid | własne silne hasło z dopisanym `:pitwall-f1` |

   W aplikacji użytkownicy wpisują samo `2137`, a administrator swoje hasło bez dopisku. Dopisek jest automatycznie dodawany przez aplikację; nie zwiększa bezpieczeństwa hasła. Jeżeli polityka haseł projektu odrzuci te wartości, dostosuj ją w ustawieniach Auth. Hasło `2137` jest publicznie znane i łatwe do odgadnięcia: każdy gracz powinien natychmiast zmienić je w aplikacji, przed dodaniem typów. Ustaw silne i unikalne hasło administratora.
3. W SQL Editor dodaj profile do wcześniej utworzonych kont:

   ```sql
   insert into public.profiles (id, name, is_admin)
   select id, case email
     when 'piotr@pitwall.invalid' then 'Piotr'
     when 'mateusz@pitwall.invalid' then 'Mateusz'
     when 'kacper@pitwall.invalid' then 'Kacper'
     when 'admin@pitwall.invalid' then 'Admin'
   end, email = 'admin@pitwall.invalid'
   from auth.users
   where email in ('piotr@pitwall.invalid', 'mateusz@pitwall.invalid', 'kacper@pitwall.invalid', 'admin@pitwall.invalid');
   ```

4. W `config.js` wpisz Project URL i publiczny klucz publishable/anon z ustawień API Supabase. Nie używaj klucza `service_role` ani secret: pliki GitHub Pages są publiczne.
5. Umieść pliki w repozytorium GitHub. W Settings → Pages wybierz wdrażanie z gałęzi, katalog główny (`/root`). Otwórz adres GitHub Pages podany w ustawieniach. Do lokalnego testowania uruchom serwer statyczny, np. `npx serve .`.

## Zasady

Za każdą prawidłowo wskazaną pozycję P1–P10 gracz otrzymuje 1 punkt, za trafnego kierowcę najszybszego okrążenia kolejny punkt. Inne trafienia nie dają punktów. Wyniki i klasyfikacja przeliczają się po edycji wyniku. Kierowca nie może powtórzyć się w pierwszej dziesiątce, ale może zostać wskazany także jako autor najszybszego okrążenia.

Baza sprawdza uprawnienia i czas startu niezależnie od zegara telefonu. Przed startem gracz widzi tylko własny typ; pozostałym widoczny jest sam fakt jego oddania. Administrator wprowadza i edytuje wyniki po starcie. Zmiana nazwy kierowcy zmienia jego wyświetlaną nazwę również w historii; wyłączenie kierowcy zachowuje stare typy.

Projekt wymaga aktywnego projektu Supabase i dostępu do internetu. Supabase Auth i baza nie są częścią GitHub Pages. Połączenie, konta i faktyczne wdrożenie należy skonfigurować przed użyciem.
