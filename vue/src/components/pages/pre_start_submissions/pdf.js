import { jsPDF } from 'jspdf';

export function createPDF(id, submission) {
  const doc = new jsPDF();
  const yMargin = 5;
  doc.props = {
    fromY: yMargin,
    yMargin,
    xMargin: 5,
    width: doc.internal.pageSize.getWidth(),
    height: doc.internal.pageSize.getHeight(),
    maybeNewPage: () => {
      if (doc.props.fromY > doc.props.height - 20) {
        doc.addPage();
        doc.props.fromY = doc.props.yMargin;
      }
    },
  };

  createBanner(doc, submission.heading);
  createComments(doc, submission.comments);
  submission.sections.forEach(s => createSection(doc, s));

  document.getElementById(id).setAttribute('src', null);
  setTimeout(() => {
    document.getElementById(id).setAttribute('src', doc.output('bloburl'));
  });
}

function createBanner(doc, heading) {
  doc.setFontSize(6);
  doc.text(`File Generated: ${new Date().toISOString()}`, doc.props.xMargin, doc.props.fromY);
  doc.props.fromY += 2;

  doc.setFontSize(14);
  const bannerHeight = doc.getFontSize();

  const halfSpacing = doc.props.width / 6;
  doc.setTextColor('white');
  doc.setFillColor('#314452');
  doc.rect(0, doc.props.fromY, doc.props.width, bannerHeight, 'F');

  const textY = doc.props.fromY + bannerHeight / 2;
  const textOpts = { align: 'center', baseline: 'middle' };
  doc.text(heading.asset, halfSpacing, textY, textOpts);
  doc.text(heading.operator, 3 * halfSpacing, textY, textOpts);
  doc.text(heading.timestamp, 5 * halfSpacing, textY, textOpts);

  doc.props.fromY += bannerHeight;
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
  doc.rect(0, doc.props.fromY, doc.props.width, height, rectActions);
  doc.text(opts.text, doc.props.xMargin, doc.props.fromY + height / 2, {
    align: opts.align || 'left',
    baseline: 'middle',
    maxWidth: opts.maxWidth,
  });

  doc.setTextColor('black');
  doc.props.fromY += height;
}

function createComments(doc, comments) {
  if (!comments || !comments.length) {
    return;
  }

  // add some margin
  doc.props.fromY += 10;

  createHeading(doc, {
    text: 'Comments',
    height: 10,
    fontSize: 18,
    fillColor: '#425866',
    textColor: 'white',
  });

  doc.props.fromY += 5;

  doc.setFontSize(10);
  const lineHeight = doc.getTextDimensions('a').h * 1.5;
  const xOffset = doc.props.xMargin + 5;
  for (const c in comments) {
    const nLines = createWrappedLine(
      doc,
      `- ${c}`,
      xOffset,
      doc.props.fromY,
      doc.props.width - xOffset,
    );
    doc.props.fromY += lineHeight * nLines;
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

  doc.props.maybeNewPage();
  doc.props.fromY -= 4;
  section.controls.forEach(c => createControl(doc, c));
  doc.props.fromY += 20;
  doc.props.maybeNewPage();
}

function createControl(doc, control) {
  doc.props.fromY += 5;
  const fontSize = 12;
  doc.setFontSize(fontSize);
  const fontHeight = doc.getTextDimensions('a').h;

  const nLines = createWrappedLine(
    doc,
    control.label,
    doc.props.xMargin,
    doc.props.fromY + doc.getFontSize(),
    doc.props.width * 0.75,
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
    doc.props.xMargin + doc.props.width - 10,
    doc.props.fromY + doc.getFontSize(),
    {
      align: 'right',
    },
  );
  doc.setTextColor('black');
  doc.props.fromY += nLines * fontHeight;

  if (control.comment) {
    doc.props.fromY += 2;
    const commentLines = createWrappedLine(
      doc,
      `- ${control.comment}`,
      doc.props.xMargin + 5,
      doc.props.fromY + doc.getFontSize(),
    );
    doc.props.fromY += fontHeight * commentLines;
  }

  doc.props.maybeNewPage();
}

function createWrappedLine(doc, text, x, y, maxWidth, opts = {}) {
  const lines = doc.splitTextToSize(text, maxWidth);
  doc.text(text, x, y, { ...opts, maxWidth });
  doc.props.maybeNewPage();
  return lines.length;
}
