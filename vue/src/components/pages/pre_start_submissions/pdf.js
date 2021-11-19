import { jsPDF } from 'jspdf';

export function createPDF(id, submission) {
  console.dir(submission);
  const doc = new jsPDF();
  doc.props = {
    fromY: 0,
    width: doc.internal.pageSize.getWidth(),
    height: doc.internal.pageSize.getHeight(),
  };

  createBanner(doc, submission.heading);
  createComments(doc, submission.comments);

  // createBanner(doc);
  // createHeading(doc, 'A Heading', 10, { color: 'cyan' });
  // createHeading(doc, 'A Subheading', 8, { color: 'cyan', fontSize: 10 });
  // createControl(doc, 'You have a key', 'fail', ['a', 'b', 'c']);
  // createControl(doc, 'You have a key', 'fail');

  // createHeading(doc, `This is a heading`, { height: 30, color: 'brown', align: 'center' });

  // createBanner(doc, props, data);

  // doc.text('Hello world!', 10, 10);
  // doc.save('a4.pdf');
  document.getElementById(id).setAttribute('src', null);
  setTimeout(() => {
    document.getElementById(id).setAttribute('src', doc.output('bloburl'));
  });
}

function createBanner(doc, heading) {
  const bannerHeight = doc.getFontSize();

  const halfSpacing = doc.props.width / 6;

  doc.setFillColor('#314452');
  doc.rect(0, doc.props.fromY, doc.props.width, bannerHeight, 'F');

  const textY = doc.props.fromY + bannerHeight / 2;
  const textOpts = { align: 'center', baseline: 'middle' };
  doc.text(heading.asset, halfSpacing, textY, textOpts);
  doc.text(heading.operator, 3 * halfSpacing, textY, textOpts);
  doc.text(heading.timestamp, 5 * halfSpacing, textY, textOpts);

  doc.props.fromY += bannerHeight;
}

function createComments(doc, comments) {
  if (!comments || !comments.length) {
    return;
  }

  // add some margin
  doc.props.fromY += 10;

  const height = 10;
  createHeading(doc, {
    text: 'Comment',
    height: 10,
    fontSize: 18,
    fillColor: '#425866',
  });

  doc.props.fromY += 10;
  const commentSize = 10;
  doc.setFontSize(10);
  for (const c in comments) {
    doc.text(c, 20, doc.props.fromY);
    doc.props.fromY += commentSize;
  }
}

function createSection(doc, section) {
  let totalHeight = 0;

  doc.props.fromY += 10;
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
  doc.rect(0, doc.props.fromY, doc.props.width, height, rectActions);
  doc.text(opts.text, 0, doc.props.fromY + height / 2, {
    align: opts.align || 'left',
    baseline: 'middle',
  });

  doc.props.fromY += height;
}

function createControl(doc, text, status, comments = []) {
  const textHeight = 12;
  doc.setFontSize(textHeight);
  doc.text(text, 0, doc.props.fromY + doc.getFontSize());
  doc.text(status, doc.props.width, doc.props.fromY + doc.getFontSize(), { align: 'right' });
  doc.props.fromY += textHeight;
  for (const c of comments) {
    doc.text(`* ${c}`, 20, doc.props.fromY + doc.getFontSize());
    doc.props.fromY += textHeight;
  }
}
