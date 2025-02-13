replace into filecap select null, 'drumee.json', 'skeleton', 'application/json', '---', 'Drumee skeleton data';
replace into filecap select null, 'skl.json', 'skeleton', 'application/json', '---', 'Drumee skeleton data';
replace into filecap select null, 'poll.json', 'form', 'application/json', '---', 'Drumee form data';
replace into filecap select null, 'form.json', 'form', 'application/json', '---', 'Drumee form data';
replace into filecap select null, 'd.ts.map', 'text', 'text/plain', '---', 'Typescript map file';
replace into filecap select null, 'scss.map', 'text', 'text/plain', '---', 'Scss map file';
replace into filecap select null, 'js.map', 'text', 'text/plain', '---', 'Javascript map file';
replace into filecap select null, 'd.ts', 'text', 'text/plain', '---', 'Typescript ';
replace into filecap select null, 'drumee.html', 'note', 'text/html', '---', "Drumee note";
update filecap set capability='---' where capability='r';