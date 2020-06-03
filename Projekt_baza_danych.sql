CREATE DATABASE siec_hoteli;

CREATE TABLE miasto(
id_miasta INT NOT NULL PRIMARY KEY IDENTITY(10,2),
nazwa_miasta VARCHAR(50) NOT NULL,
nazwa_kraju VARCHAR(50) NOT NULL,
);

CREATE TABLE hotel (
id_hotelu INT NOT NULL PRIMARY KEY IDENTITY(100,1),
nazwa_hotelu VARCHAR(70) NOT NULL,
id_miasta INT NOT NULL  FOREIGN KEY REFERENCES miasto (id_miasta),
adres_hotelu VARCHAR(100) NOT NULL,
cena_bazowa_za_pokoj INT NOT NULL,
cena_za_polaczenie_telefoniczne FLOAT(2) NOT NULL,
CONSTRAINT check_cena_bazowa_za_pokoj CHECK (cena_bazowa_za_pokoj > 0),
CONSTRAINT cena_za_polaczenie_telefoniczne CHECK (cena_za_polaczenie_telefoniczne > 0)
);

CREATE TABLE pokoj (
id_pokoju INT NOT NULL PRIMARY KEY IDENTITY(100,1),
id_hotelu INT NOT NULL FOREIGN KEY REFERENCES hotel (id_hotelu),
numer_telefonu_pokoju CHAR(5) NOT NULL UNIQUE,
liczba_pomieszczen INT NOT NULL,
liczba_przewidzianych_osob INT NOT NULL,
CONSTRAINT check_liczba_pomieszczen CHECK (liczba_pomieszczen > 0),
CONSTRAINT ckeck_liczba_przewidzianych_osob CHECK (liczba_przewidzianych_osob > 0),
CONSTRAINT check_numer_telefonu CHECK (numer_telefonu_pokoju LIKE '[0-9][0-9][0-9][0-9][0-9]'),
);

CREATE TABLE usluga (
id_uslugi INT NOT NULL PRIMARY KEY IDENTITY(1,1),
nazwa_uslugi VARCHAR(50) NOT NULL,
cena_uslugi INT NOT NULL,
CONSTRAINT check_cena_uslugi CHECK (cena_uslugi > 0),
);

CREATE TABLE klient (
id_klienta INT NOT NULL PRIMARY KEY IDENTITY(1000,1),
imie_klienta VARCHAR(20),
nazwisko_klienta VARCHAR(40) NOT NULL, 
pesel_klienta CHAR(9) NOT NULL,
adres_zamieszkania VARCHAR(100) NOT NULL,
numer_telefonu_klienta CHAR(9) UNIQUE,
CONSTRAINT check_pesel CHECK (pesel_klienta LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9)'),
CONSTRAINT check_numer_telefonu_klienta CHECK (numer_telefonu_klienta LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
);

CREATE TABLE rezerwacja (
id_rezerwacji INT NOT NULL IDENTITY(1000,1),
id_pokoju INT NOT NULL FOREIGN KEY REFERENCES pokoj (id_pokoju),
id_klienta INT NOT NULL FOREIGN KEY REFERENCES klient (id_klienta),
liczba_dni_rezerwacji INT NOT NULL,
data_rezerwacji DATE NOT NULL, 
CONSTRAINT check_liczba_dni_rezerwacji CHECK (liczba_dni_rezerwacji > 0),
CONSTRAINT check_data_rezerwacji CHECK (data_rezerwacji > GETDATE()),
CONSTRAINT id_primary_key PRIMARY KEY (id_rezerwacji)
);

CREATE TABLE usluga_dla_pokoju (
id_uslugi INT NOT NULL FOREIGN KEY REFERENCES usluga (id_uslugi), 
id_pokoju INT NOT NULL FOREIGN KEY REFERENCES pokoj (id_pokoju)
PRIMARY KEY (id_uslugi, id_pokoju)
);

CREATE TABLE sprzatanie (
id_sprzatania INT NOT NULL PRIMARY KEY IDENTITY(1,1),
id_pokoju INT NOT NULL FOREIGN KEY REFERENCES pokoj (id_pokoju),
data_rozpoczecia_sprzatania DATETIME NOT NULL,
data_zakonczenia_sprzatania DATETIME DEFAULT GETDATE(), 
rodzaj_sprzatania VARCHAR(10),
CONSTRAINT check_data_sprzatania CHECK (data_rozpoczecia_sprzatania < data_zakonczenia_sprzatania),
CONSTRAINT check_data_zakonczenia_sprzatania CHECK (data_zakonczenia_sprzatania < GETDATE()),
CONSTRAINT check_rodzaj_sprzatania CHECK (UPPER(rodzaj_sprzatania) IN ('PODSTAWOWE', 'PELNE'))
);

CREATE TABLE rozmowy_telefoniczne (
id_rozmowy_telefonicznej INT NOT NULL PRIMARY KEY IDENTITY(100,1),
id_pokoju INT NOT NULL FOREIGN KEY REFERENCES pokoj (id_pokoju),
numer_telefonu VARCHAR(9) NOT NULL,
godzina_rozpoczecia_rozmowy TIME NOT NULL,
data_zakonczenia_rozmowy DATETIME DEFAULT GETDATE(),
CONSTRAINT check_data_rozmowy CHECK (godzina_rozpoczecia_rozmowy < cast(data_zakonczenia_rozmowy as time(0))),
CONSTRAINT check_data_zakonczenia_rozmowy CHECK (data_zakonczenia_rozmowy < GETDATE()),
CONSTRAINT check_numer_telefonu_rozmowcy CHECK (numer_telefonu NOT LIKE '%^(0-9)%')
);


--1. Wy�wietlenie liczby pokoi w ka�dym z hoteli.
SELECT COUNT(*) as 'Liczba pokoi', nazwa_hotelu FROM pokoj p, hotel h
WHERE p.id_hotelu = h.id_hotelu
GROUP BY nazwa_hotelu

--2. Wy�wietlenie nazwy hotelu, ceny bazowej za pok�j, nazwa miasta przy tworzeniu rankingu hoteli na podstawie cen pokoi bez przeskoku. 
SELECT nazwa_hotelu, cena_bazowa_za_pokoj, nazwa_miasta,
DENSE_RANK() OVER (ORDER BY cena_bazowa_za_pokoj DESC) AS 'Ranking cen pokoi'
FROM hotel h, miasto m
WHERE h.id_miasta = m.id_miasta

--3. Wy�wietlenie �redniej ceny po��cze� telefonicznych hoteli dla miasta zaokr�glone do drugiej liczby po przecinku wraz z nazw� miasta.
SELECT nazwa_miasta, ROUND(AVG(cena_za_polaczenie_telefoniczne) OVER (PARTITION BY nazwa_miasta), 2) as 'Srednia cena polaczen telefonicznych'
FROM hotel h, miasto m
WHERE h.id_miasta = m.id_miasta
ORDER BY m.nazwa_miasta

--4. Utw�rz pust� tabel� archiwum_rezerwacji na podstawie tabeli rezerwacja pomijaj�c kolumn� id_rezerwacji. 
SELECT id_pokoju, id_klienta, liczba_dni_rezerwacji, data_rezerwacji INTO archiwum_rezerwacji 
FROM rezerwacja
WHERE 1 = 0

--5. Dodaj do tabeli archiwum_rezerwacji kolumn� cena_rezerwacji typu ca�kowitego oraz kolumn� id_rezerwacji_arch typu ca�kowitego przyrostowego 
-- od 10000 co 1 b�d�ca kluczem g��wnym. 
ALTER TABLE archiwum_rezerwacji 
ADD cena_rezerwacji INT,
	id_rezerwacji_arch INT PRIMARY KEY IDENTITY(10000,1)

--6. Na kolumny za�� ograniczenia takie jak przy tabeli rezerwacja, przy czym data_rezerwacji musi by� przed aktualn� dat�.
ALTER TABLE archiwum_rezerwacji 
ADD CONSTRAINT check_liczba_dni_rezerwacji_arch CHECK (liczba_dni_rezerwacji > 0),
	CONSTRAINT check_data_rezerwacji_arch CHECK (data_rezerwacji < GETDATE()),
	CONSTRAINT id_pokoju_arch_foreign_key FOREIGN KEY (id_pokoju) REFERENCES pokoj (id_pokoju),
	CONSTRAINT id_kleinta_arch_foreign_key FOREIGN KEY (id_klienta) REFERENCES klient (id_klienta)

--7. W tabeli rezerwacja zdejmij restrykcj� dotycz�c� daty rezerwacji (data_rezerwacji musi by� dat� p�niejsz� ni� aktualna data).
ALTER TABLE rezerwacja
DROP check_data_rezerwacji;

--8. Dodaj do tabeli rezerwacja 6 rekordy z dat� rezerwacji, kt�ra ju� si� odby�a.
INSERT INTO rezerwacja VALUES (123, 1003, 8, '2020/05/02');
INSERT INTO rezerwacja VALUES (104, 1000, 4, '2020/01/05');
INSERT INTO rezerwacja VALUES (121, 1002, 3, '2020/02/16');
INSERT INTO rezerwacja VALUES (145, 1025, 5, '2020/04/22');
INSERT INTO rezerwacja VALUES (155, 1013, 12, '2020/02/11');
INSERT INTO rezerwacja VALUES (160, 1021, 5, '2020/02/25');

--9. Przenie� z tabeli rezerwacja te rekordy, kt�re maja przesz�� dat� do tabeli archiwum_rezerwacji. 
INSERT INTO archiwum_rezerwacji (id_pokoju, id_klienta, liczba_dni_rezerwacji, data_rezerwacji)
SELECT id_pokoju, id_klienta, liczba_dni_rezerwacji, data_rezerwacji FROM rezerwacja
WHERE data_rezerwacji < GETDATE()

--10. Usu� z tabeli rezerwacja wszystkie rekordy, kt�re maj� przesz�� dat� rezerwacji. Na�� ponownie restrykcj� na tabel� rezerwacja by data_rezerwacji mog�a by� 
-- tylko dat� p�niejsz� ni� aktualna data. 
DELETE FROM rezerwacja WHERE data_rezerwacji < GETDATE()

ALTER TABLE rezerwacja
ADD CONSTRAINT check_data_rezerwacji CHECK (data_rezerwacji > GETDATE());

--11. Dodaj synonim dla tabeli archiwum_rezerwacji ustawiaj�c jego warto�� na arch oraz dla tabeli rozmowy_telefoniczne na warto�� tel.
CREATE SYNONYM arch FOR archiwum_rezerwacji;
CREATE SYNONYM tel FOR rozmowy_telefoniczne;


--12. W tabeli archiwum_rezerwacji ustaw warto�ci kolumny cena_rezerwacji na warto�� iloczynu cena_bazowa_za_pokoj razy liczba_dni_rezerwacji.
SELECT * FROM arch
UPDATE arch
SET cena_rezerwacji = h.cena_bazowa_za_pokoj * a.liczba_dni_rezerwacji FROM hotel h, arch a, pokoj p
WHERE a.id_pokoju = p.id_pokoju
	AND p.id_hotelu = h.id_hotelu

--13. Dodaj funkcj� zwracaj�c� wsp�czynnik z jakim trzeba b�dzie pomno�y� cen� za po��czenie telefoniczne. Funkcja ma przyjmowa� dwa argumenty: 
-- numer_telefonu, id_pokoju. Je�li numer telefonu, na kt�ry zosta�o wykonane po��czenie nale�y do kt�rego� z pokoi w hotelu z kt�rego wykonano po��czenie 
-- (na podstawie id_pokoju uzyskujemy id_hotelu z kt�rego wykonano po��czenie) wtedy wsp�czynnik ustawiany jest na 0. Dla numeru telefonu pokoju znajduj�cego 
-- si� w innym hotelu wsp�czynnik ustawiany jest na 0.5, dla numer�w telefon�w spoza hotelu wsp�czynnik ustawiany jest na 1. 

GO
CREATE FUNCTION obliczWspoczynnik 
(
	@numer_telefonu VARCHAR, 
	@id_pokoju INT
)
RETURNS FLOAT(2)
AS BEGIN
      DECLARE @wspolczynnik FLOAT(2); 
	  
      IF EXISTS (SELECT * FROM pokoj p WHERE p.numer_telefonu_pokoju = @numer_telefonu
	  AND p.id_hotelu = (SELECT id_hotelu FROM pokoj p WHERE 104 = p.id_pokoju)) 
		BEGIN
			SET @wspolczynnik = 0.00
		END
	  ELSE IF EXISTS (SELECT * FROM pokoj p WHERE p.numer_telefonu_pokoju = @numer_telefonu
	  AND p.id_hotelu != (SELECT id_hotelu FROM pokoj p WHERE 104 = p.id_pokoju)) 
		BEGIN
			SET @wspolczynnik = 0.50
	    END
	  ELSE
		BEGIN
			SET @wspolczynnik = 1.00
		END
    RETURN @wspolczynnik; 
END; 
GO

--14. Dodaj do tabeli rezerwacja kolumn� cena_za_telefon typu zmiennoprzecinkowego z dwoma miejscami po przecinku. Wstaw do nowo utworzonej kolumny 
-- cena_za_polaczenie_telefoniczne pomno�on� przez r�nic� minut pomi�dzy godzin� rozpocz�cia a godzin� zako�czenia rozmowy. 
ALTER TABLE arch
ADD cena_za_telefon FLOAT(2)

UPDATE arch
SET cena_za_telefon = t.suma_cen
FROM 
    (
        SELECT ar.id_pokoju,SUM(DATEDIFF(MINUTE, rt.godzina_rozpoczecia_rozmowy,CAST(rt.data_zakonczenia_rozmowy as time)) * h.cena_za_polaczenie_telefoniczne) suma_cen
        FROM tel rt, hotel h, pokoj p, arch ar
        WHERE ar.id_pokoju = p.id_pokoju
	AND rt.id_pokoju = p.id_pokoju
	AND p.id_hotelu = h.id_hotelu
        GROUP BY ar.id_pokoju
    ) t
WHERE t.id_pokoju = arch.id_pokoju
SELECT * FROM arch;

UPDATE arch
SET cena_za_telefon = dbo.obliczWspoczynnik(rt.numer_telefonu, rt.id_pokoju)
FROM arch ar, tel rt
WHERE ar.id_pokoju = rt.id_pokoju
SELECT * FROM arch;
SELECT * FROM tel;
SELECT * FROM pokoj
SELECT dbo.obliczWspoczynnik('12643', 120)
SELECT dbo.obliczWspoczynnik('12643', 104)

--
--
--UPDATE archiwum_rezerwacji
--IF (SELECT COUNT(*) FROM pokoj, archiwum_rezerwacji ar 
--WHERE ar.numer_telefonu = p.numer_telefonu_pokoju
--AND 

--SELECT 1 FROM pokoj p, archiwum_rezerwacji ar WHERE p.numer_telefonu_pokoju = ar.numer_telefonu

--IF EXISTS (SELECT * FROM pokoj p,rozmowy_telefoniczne rt WHERE rt.numer_telefonu = p.numer_telefonu_pokoju) 
--BEGIN
--   SELECT 0 
--END
--ELSE
--BEGIN
--    SELECT 1
--END





--15. Dodaj do tabeli archiwum_rezerwacji kolumn� cena_za_uslugi typu zmiennoprzecinkowego z dwoma miejscami po przecinku. 
-- Wstaw do nowo utworzonej kolumny  cena_uslugi pomno�on� razy liczba_dni_rezerwacji.
ALTER TABLE arch
ADD cena_za_uslugi FLOAT(2)

UPDATE arch
SET cena_za_uslugi = t.suma_cen
FROM 
    (
        SELECT up.id_pokoju ,SUM(u.cena_uslugi) suma_cen
        FROM arch ar, usluga_dla_pokoju up, usluga u
        WHERE ar.id_pokoju = up.id_pokoju
		AND up.id_uslugi = u.id_uslugi
        GROUP BY up.id_pokoju
    ) t
WHERE t.id_pokoju = arch.id_pokoju
SELECT * FROM arch

--16. Dodaj do tabeli archiwum_rezerwacji kolumn� cena_calkowita typu zmiennoprzecinkowego z dwoma miejscami po przecinku. 
-- Wstaw do nowo utworzonej kolumny sum� kolumn cena_za_uslugi, cena_za_telefon, cena_rezerwacji. 
ALTER TABLE arch
ADD cena_calkowita FLOAT(2)

UPDATE arch
SET cena_calkowita = cena_za_uslugi + cena_za_telefon + cena_rezerwacji
FROM arch
SELECT * FROM arch

