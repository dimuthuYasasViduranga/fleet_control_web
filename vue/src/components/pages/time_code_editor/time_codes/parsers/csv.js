import { parseString } from '@fast-csv/parse';
import { textFromFile, downloadFromText } from '@/code/io';
import { lowifyKeys } from '@/code/helpers';

const CSV_NOTES = [
  ['required', ['Name', 'Code', 'Group']],
  ['optional', ['Category']],
];

const CSV_EXAMPLE = `"name","code","group","category"
"Haul Ore","1001","Ready","Productive Time"
"Scheduled Relocation","2001","Process","Non Productive Time"
"Personal Break","3001","Standby","Operating Standby"
"Planned Maintenance","4001","Down","Scheduled Downtime"`;

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
  return downloadFromText(CSV_EXAMPLE, 'csv-time-code-list.csv');
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

  const name = props.name;
  const code = props.code;
  const group = props.group;
  const category = props.category;

  return {
    name,
    code,
    group,
    category,
  };
}
