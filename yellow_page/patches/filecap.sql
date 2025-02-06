replace into filecap select null, 'drumee.json', 'skeleton', 'application/json', '---', 'Drumee skeleton data';
replace into filecap select null, 'skl.json', 'skeleton', 'application/json', '---', 'Drumee skeleton data';
replace into filecap select null, 'poll.json', 'form', 'application/json', '---', 'Drumee form data';
replace into filecap select null, 'form.json', 'form', 'application/json', '---', 'Drumee form data';
replace into filecap select null, 'd.ts.map', 'text', 'plain/tex', '---', 'Typescript map file';
replace into filecap select null, 'scss.map', 'text', 'plain/tex', '---', 'Scss map file';
replace into filecap select null, 'js.map', 'text', 'plain/tex', '---', 'Javascript map file';
replace into filecap select null, 'd.ts', 'text', 'plain/tex', '---', 'Typescript ';
update filecap set capability='---' where capability='r';