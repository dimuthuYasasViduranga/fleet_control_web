import { parseString } from '@fast-csv/parse';
import { textFromFile, downloadFromText } from '@/code/io';
import { anyOf, lowifyKeys } from '@/code/helpers';

const CSV_NOTES = [
  ['required', ['Name', 'Employee ID']],
  ['optional', ['shortname']],
];

const CSV_EXAMPLE = `"name","short_name","employee_id"
"Operator A","","0001"
"Operator B","OP B","5136"`;

export function getDefinition() {
  return {
    type: 'csv',
    notes: CSV_NOTES,
    extensions: ['.csv'],
    example: CSV_EXAMPLE,
    download,
    parse: parseCSV,
  };
}

function download() {
  return downloadFromText(CSV_EXAMPLE, 'csv-operator-list.csv');
}

export function parseCSV(file) {
  return textFromFile(file).then(textToCSVRows).then(extractOperators);
}

function textToCSVRows(text) {
  return new Promise((resolve, reject) => {
    const rows = [];
    parseString(text, { headers: true })
      .on('error', error => reject(error))
      .on('data', row => rows.push(row))
      .on('end', () => resolve(rows));
  });
}

function extractOperators(rows) {
  return rows.map(rowToOperator).filter(r => r);
}

function rowToOperator(row) {
  const props = lowifyKeys(row);

  const name = props.name || props.fullname;
  const nickname = anyOf(props, ['nickname', 'short_name', 'shortname', 'short name']);
  const employeeId = anyOf(props, [
    'employeeid',
    'employee_id',
    'employee id',
    'operatorid',
    'operator_id',
    'operator id',
    'id',
  ]);

  return {
    name,
    nickname,
    employeeId,
  };
}
