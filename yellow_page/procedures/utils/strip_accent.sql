DELIMITER $
CREATE FUNCTION strip_accents(input_text TEXT)
RETURNS TEXT
DETERMINISTIC
BEGIN
    SET input_text = REPLACE(input_text, 'á', 'a');
    SET input_text = REPLACE(input_text, 'à', 'a');
    SET input_text = REPLACE(input_text, 'â', 'a');
    SET input_text = REPLACE(input_text, 'ä', 'a');
    SET input_text = REPLACE(input_text, 'ã', 'a');
    SET input_text = REPLACE(input_text, 'é', 'e');
    SET input_text = REPLACE(input_text, 'è', 'e');
    SET input_text = REPLACE(input_text, 'ê', 'e');
    SET input_text = REPLACE(input_text, 'ë', 'e');
    SET input_text = REPLACE(input_text, 'í', 'i');
    SET input_text = REPLACE(input_text, 'ì', 'i');
    SET input_text = REPLACE(input_text, 'î', 'i');
    SET input_text = REPLACE(input_text, 'ï', 'i');
    SET input_text = REPLACE(input_text, 'ó', 'o');
    SET input_text = REPLACE(input_text, 'ò', 'o');
    SET input_text = REPLACE(input_text, 'ô', 'o');
    SET input_text = REPLACE(input_text, 'ö', 'o');
    SET input_text = REPLACE(input_text, 'õ', 'o');
    SET input_text = REPLACE(input_text, 'ú', 'u');
    SET input_text = REPLACE(input_text, 'ù', 'u');
    SET input_text = REPLACE(input_text, 'û', 'u');
    SET input_text = REPLACE(input_text, 'ü', 'u');
    SET input_text = REPLACE(input_text, 'ñ', 'n');
    SET input_text = REPLACE(input_text, 'ç', 'c');
    SET input_text = REPLACE(input_text, 'Á', 'A');
    SET input_text = REPLACE(input_text, 'À', 'A');
    SET input_text = REPLACE(input_text, 'Â', 'A');
    SET input_text = REPLACE(input_text, 'Ä', 'A');
    SET input_text = REPLACE(input_text, 'Ã', 'A');
    SET input_text = REPLACE(input_text, 'É', 'E');
    SET input_text = REPLACE(input_text, 'È', 'E');
    SET input_text = REPLACE(input_text, 'Ê', 'E');
    SET input_text = REPLACE(input_text, 'Ë', 'E');
    SET input_text = REPLACE(input_text, 'Í', 'I');
    SET input_text = REPLACE(input_text, 'Ì', 'I');
    SET input_text = REPLACE(input_text, 'Î', 'I');
    SET input_text = REPLACE(input_text, 'Ï', 'I');
    SET input_text = REPLACE(input_text, 'Ó', 'O');
    SET input_text = REPLACE(input_text, 'Ò', 'O');
    SET input_text = REPLACE(input_text, 'Ô', 'O');
    SET input_text = REPLACE(input_text, 'Ö', 'O');
    SET input_text = REPLACE(input_text, 'Õ', 'O');
    SET input_text = REPLACE(input_text, 'Ú', 'U');
    SET input_text = REPLACE(input_text, 'Ù', 'U');
    SET input_text = REPLACE(input_text, 'Û', 'U');
    SET input_text = REPLACE(input_text, 'Ü', 'U');
    SET input_text = REPLACE(input_text, 'Ñ', 'N');
    SET input_text = REPLACE(input_text, 'Ç', 'C');
    
    RETURN input_text;
END$

DELIMITER ;