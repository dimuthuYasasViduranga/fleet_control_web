import { formatDateIn } from '@/code/time';
import { jsPDF } from 'jspdf';

export function createPDF(submissionOrSubmissions, timezone, opts = {}) {
  const doc = new jsPDF();
  const yMargin = 5;
  doc.$ = {
    fromY: yMargin,
    timezone,
    yMargin,
    xMargin: 5,
    width: doc.internal.pageSize.getWidth(),
    height: doc.internal.pageSize.getHeight(),
    maybeNewPage: () => {
      if (doc.$.fromY > doc.$.height - 30) {
        doc.addPage();
        doc.$.fromY = doc.$.yMargin;
      }
    },
  };

  if (!Array.isArray(submissionOrSubmissions)) {
    submissionOrSubmissions = [submissionOrSubmissions];
  }

  createSubmissions(doc, submissionOrSubmissions);

  if (opts.iframe) {
    const id = opts.iframe;
    document.getElementById(id).setAttribute('src', null);
    setTimeout(() => {
      document.getElementById(id).setAttribute('src', doc.output('bloburl'));
    });
  }

  if (opts.filename) {
    doc.save(opts.filename);
  }
}

function createSubmission(doc, submission) {
  createBanner(doc, submission.heading);
  createComments(doc, submission.comments);
  submission.sections.forEach(s => createSection(doc, s));
}

function createSubmissions(doc, submissions) {
  submissions.forEach((sub, index) => {
    if (index !== 0) {
      doc.$.fromY = 0;
      doc.addPage();
    }
    createSubmission(doc, sub);
  });

  // add page numbers
  const pageCount = doc.internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.text(`${i}`, 105, 285);
  }
}

function createBanner(doc, heading) {
  doc.setFontSize(6);
  doc.text(`File Generated: ${new Date().toISOString()}`, doc.$.xMargin, doc.$.fromY);
  doc.$.fromY += 2;

  doc.setFontSize(14);
  const bannerHeight = doc.getFontSize();

  const halfSpacing = doc.$.width / 6;
  doc.setTextColor('white');
  doc.setFillColor('#314452');
  doc.rect(0, doc.$.fromY, doc.$.width, bannerHeight, 'F');

  const textY = doc.$.fromY + bannerHeight / 2;
  const textOpts = { align: 'center', baseline: 'middle' };
  doc.text(heading.asset, halfSpacing, textY, textOpts);
  doc.text(heading.operator, 3 * halfSpacing, textY, textOpts);
  const formattedTimestamp = formatDateIn(heading.timestamp, doc.$.timezone, {
    format: 'yyyy-MM-dd HH:mm:ss',
  });
  doc.text(formattedTimestamp, 5 * halfSpacing, textY, textOpts);

  doc.$.fromY += bannerHeight;
}

function createHeading(doc, opts = {}) {
  const height = opts.height;
  if (opts.fontSize) {
    doc.setFontSize(opts.fontSize);
  }

  let rectActions = null;
  if (opts.fillColor) {
    rectActions = 'F';
    doc.setFillColor(opts.fillColor);
  }

  if (opts.textColor) {
    doc.setTextColor(opts.textColor);
  }
  doc.rect(0, doc.$.fromY, doc.$.width, height, rectActions);
  doc.text(opts.text, doc.$.xMargin, doc.$.fromY + height / 2, {
    align: opts.align || 'left',
    baseline: 'middle',
    maxWidth: opts.maxWidth,
  });

  doc.setTextColor('black');
  doc.$.fromY += height;
}

function createComments(doc, comments) {
  if (!comments || !comments.length) {
    return;
  }

  // add some margin
  doc.$.fromY += 10;

  createHeading(doc, {
    text: 'Comments',
    height: 10,
    fontSize: 18,
    fillColor: '#425866',
    textColor: 'white',
  });

  doc.$.fromY += 5;

  doc.setFontSize(10);
  const lineHeight = getTextHeight(doc) * 1.5;
  const xOffset = doc.$.xMargin + 5;
  for (const c of comments) {
    const nLines = createWrappedLine(doc, `- ${c}`, xOffset, doc.$.fromY, doc.$.width - xOffset);
    doc.$.fromY += lineHeight * nLines;
  }
}

function createSection(doc, section) {
  // title
  createHeading(doc, {
    text: section.title,
    height: 10,
    fontSize: 18,
    fillColor: '#425866',
    textColor: 'white',
  });

  // subtitle
  if (section.details) {
    createHeading(doc, {
      text: section.title,
      height: 8,
      fontSize: 10,
      fillColor: '#425866',
      textColor: 'white',
    });
  }

  doc.$.maybeNewPage();
  doc.$.fromY -= 4;
  section.controls.forEach(c => createControl(doc, c));
  doc.$.fromY += 20;
  doc.$.maybeNewPage();
}

function createControl(doc, control) {
  const fontSize = 12;
  doc.setFontSize(fontSize);
  const fontHeight = getTextHeight(doc);

  const nLines = createWrappedLine(
    doc,
    control.label,
    doc.$.xMargin,
    doc.$.fromY + doc.getFontSize(),
    doc.$.width * 0.75,
  );

  let textColor = 'gray';
  switch (control.status) {
    case 'Pass':
      textColor = 'green';
      break;
    case 'Fail':
      textColor = 'red';
      break;
  }
  doc.setTextColor(textColor);
  doc.text(
    control.status.toUpperCase(),
    doc.$.xMargin + doc.$.width - 10,
    doc.$.fromY + doc.getFontSize(),
    {
      align: 'right',
    },
  );
  doc.setTextColor('black');
  doc.$.fromY += nLines * fontHeight;

  if (control.comment) {
    doc.$.fromY += 2;
    const commentLines = createWrappedLine(
      doc,
      `- ${control.comment}`,
      doc.$.xMargin + 5,
      doc.$.fromY + doc.getFontSize(),
    );
    doc.$.fromY += fontHeight * commentLines;
  }

  doc.$.fromY += fontHeight;

  doc.$.maybeNewPage();

  createTicket(doc, control.ticket);
}

function createTicket(doc, ticket) {
  if (!ticket.status) {
    return;
  }

  doc.$.fromY += 5;

  const text = `${ticket.status} (Ref: ${ticket.reference || '# not given #'}) - ${ticket.details ||
    'No details given'}`;

  doc.setFillColor('#fef6c9');
  const maxWidth = doc.$.width - doc.$.xMargin;
  const lines = doc.splitTextToSize(text, maxWidth).length;

  // return;
  doc.rect(
    doc.$.xMargin,
    doc.$.fromY,
    doc.$.width - 2 * doc.$.xMargin,
    (lines + 0.75) * getTextHeight(doc) * doc.getLineHeightFactor(),
    'F',
  );
  doc.text(text, doc.$.xMargin * 2, doc.$.fromY + 5, { maxWidth });
  doc.$.fromY += (lines + 1) * getTextHeight(doc);
  doc.$.maybeNewPage();
}

function createWrappedLine(doc, text, x, y, maxWidth, opts = {}) {
  const lines = doc.splitTextToSize(text, maxWidth);
  doc.text(text || '', x, y, { ...opts, maxWidth });
  doc.$.maybeNewPage();
  return lines.length;
}

function getTextHeight(doc) {
  return doc.getTextDimensions('a').h;
}
