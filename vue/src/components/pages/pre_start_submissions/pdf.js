import { jsPDF } from 'jspdf';

export function createPDF(arr) {
  const doc = new jsPDF();

  doc.text('Hello world!', 10, 10);
  doc.save('a4.pdf');
}
