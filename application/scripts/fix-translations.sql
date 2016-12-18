/*
 * The MIT License (MIT)
 * Copyright (c) 2016 University of Washington
 *
 * Author: Zach Ploskey <zach@ploskey.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 ************************
 * fix-translations.sql *
 ************************
 *
 * There was an issue with a lot of duplicated translations
 * for records with elements that had multiple entries per
 * element with multilanguage translations of those elements.
 * This was due to the way we initially populated the translations table,
 * i.e. ignoring that there could be multiple translations per
 * element / record pair. It is saved here for posterity
 * in case we ever need to do something like this again.
 *
 * The following MySQL script creates a table tmp_translations
 * and then creates and calls a stored procedure called
 * insertAllFixedTranslations(). It filters all the translations
 * for wrong translations by removing all entries that have
 * a duplicate record_id/element_id/text triplet.
 *
 * Assuming the query works, you will probably then want to run the
 * following two commands to move the new table into production.
 *
 * RENAME TABLE omeka_multilanguage_translations TO old_translation;
 * RENAME TABLE tmp_translations TO omeka_multilanguage_translations;
 */

DROP TABLE IF EXISTS tmp_translations;
CREATE TABLE tmp_translations LIKE omeka_multilanguage_translations;

DROP PROCEDURE IF EXISTS insertAllFixedTranslations;
DELIMITER //
CREATE PROCEDURE insertAllFixedTranslations()
BEGIN
    DECLARE nrows INT(11);
    DECLARE row INT(11);
    DECLARE record INT(11);
    DECLARE element INT(11);

    DROP TEMPORARY TABLE IF EXISTS record_element_pairs;

    CREATE TEMPORARY TABLE record_element_pairs
    SELECT @curRow := @curRow + 1 AS r, t.*
    FROM (
        SELECT record_id, element_id
        FROM omeka_multilanguage_translations as mlt
        GROUP BY record_id, element_id
    ) as t
    JOIN (SELECT @curRow := 0) r;

    SELECT COUNT(*) FROM record_element_pairs INTO nrows;

    SET row = 0;
    WHILE row < nrows DO
        SET row = row + 1;

        SELECT pair.record_id, pair.element_id
        INTO record, element
        FROM record_element_pairs AS pair
        WHERE pair.r = row;

        INSERT INTO tmp_translations
        (element_id, record_id, record_type, locale_code, text, translation)
        SELECT element_id, record_id, record_type, locale_code, text, translation
        FROM (
            SELECT (SELECT @i := @i + 1) as i, t1.*
            FROM (
                SELECT element_id, record_id, record_type, locale_code, text
                FROM omeka_multilanguage_translations
                WHERE record_id = record AND element_id = element
                GROUP BY text ORDER BY id
            ) as t1
            JOIN (SELECT @i := 0) as i
        ) AS t3
        JOIN (
            SELECT (SELECT @j := @j + 1) as i, t2.* FROM (
                SELECT translation FROM omeka_multilanguage_translations
                WHERE record_id = record AND element_id = element
                GROUP BY translation ORDER BY id
            ) as t2
            JOIN (SELECT @j := 0) as i
        ) AS t4
        ON t3.i = t4.i;
    END WHILE;

    DROP TEMPORARY TABLE record_element_pairs;
END //
DELIMITER ;

CALL insertAllFixedTranslations();
