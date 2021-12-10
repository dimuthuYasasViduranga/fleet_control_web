import { fromGraph } from './graph';

/*
vertex
{
id: 1,
data: {
  lat: -32.847238579805285,
  lng: 116.06406765162046,
},

adjacency
[
    {
      id: 9,
      startVertexId: 1,
      endVertexId: 146,
      data: {
        distance: 81.56756173760428,
      },
    },
    {
      id: 10,
      startVertexId: 1,
      endVertexId: 2,
      data: {
        distance: 155.06799537690972,
      },
    },
  ],

*/

const vertices = {
  43: {
    id: 43,
    data: {
      lat: -22.03350967751859,
      lng: 146.39269578390596,
    },
  },
  54: {
    id: 54,
    data: {
      lat: -22.034467022907165,
      lng: 146.37327837919307,
    },
  },
  55: {
    id: 55,
    data: {
      lat: -22.032796222129953,
      lng: 146.3691585061462,
    },
  },
  90: {
    id: 90,
    data: {
      lat: -22.033266980748458,
      lng: 146.37398621330757,
    },
  },
  91: {
    id: 91,
    data: {
      lat: -22.03286668313199,
      lng: 146.3744421888401,
    },
  },
  117: {
    id: 117,
    data: {
      lat: -22.03195241044057,
      lng: 146.36993493542542,
    },
  },
  118: {
    id: 118,
    data: {
      lat: -22.031276124299243,
      lng: 146.37135114178528,
    },
  },
  119: {
    id: 119,
    data: {
      lat: -22.03063961674483,
      lng: 146.37285317883362,
    },
  },
  120: {
    id: 120,
    data: {
      lat: -22.02867040337942,
      lng: 146.37319650158753,
    },
  },
  121: {
    id: 121,
    data: {
      lat: -22.026919968509596,
      lng: 146.3730677555548,
    },
  },
  122: {
    id: 122,
    data: {
      lat: -22.02616409221811,
      lng: 146.3729390095221,
    },
  },
  134: {
    id: 134,
    data: {
      lat: -22.0322053193729,
      lng: 146.3751637030651,
    },
  },
  135: {
    id: 135,
    data: {
      lat: -22.031986521659725,
      lng: 146.3757376957943,
    },
  },
  136: {
    id: 136,
    data: {
      lat: -22.03104170947044,
      lng: 146.37695005426903,
    },
  },
  137: {
    id: 137,
    data: {
      lat: -22.029470323656547,
      lng: 146.3786398459484,
    },
  },
  138: {
    id: 138,
    data: {
      lat: -22.030365418979247,
      lng: 146.37944450865288,
    },
  },
  139: {
    id: 139,
    data: {
      lat: -22.03344785901657,
      lng: 146.37512789914004,
    },
  },
  153: {
    id: 153,
    data: {
      lat: -22.031567943501358,
      lng: 146.37537470783894,
    },
  },
  154: {
    id: 154,
    data: {
      lat: -22.030812092019765,
      lng: 146.37611499752705,
    },
  },
  155: {
    id: 155,
    data: {
      lat: -22.03064301942562,
      lng: 146.37654415096944,
    },
  },
  156: {
    id: 156,
    data: {
      lat: -22.029698198271408,
      lng: 146.37765994991963,
    },
  },
  157: {
    id: 157,
    data: {
      lat: -22.029270540307966,
      lng: 146.37831440891927,
    },
  },
  169: {
    id: 169,
    data: {
      lat: -22.033245649962875,
      lng: 146.37735993979928,
    },
  },
  170: {
    id: 170,
    data: {
      lat: -22.03431973503066,
      lng: 146.3787332308149,
    },
  },
  174: {
    id: 174,
    data: {
      lat: -22.033721132139547,
      lng: 146.3714115617187,
    },
  },
  175: {
    id: 175,
    data: {
      lat: -22.033378021066802,
      lng: 146.37048888181758,
    },
  },
  181: {
    id: 181,
    data: {
      lat: -22.034024887944827,
      lng: 146.37008556234755,
    },
  },
  182: {
    id: 182,
    data: {
      lat: -22.03501940596108,
      lng: 146.36860498297133,
    },
  },
  183: {
    id: 183,
    data: {
      lat: -22.036059891030835,
      lng: 146.36679585664461,
    },
  },
  189: {
    id: 189,
    data: {
      lat: -22.034926148267807,
      lng: 146.37036855905245,
    },
  },
  190: {
    id: 190,
    data: {
      lat: -22.036099671313757,
      lng: 146.36959608285616,
    },
  },
  191: {
    id: 191,
    data: {
      lat: -22.038168230621114,
      lng: 146.36867340295504,
    },
  },
  197: {
    id: 197,
    data: {
      lat: -22.031642562466615,
      lng: 146.36619734739375,
    },
  },
  198: {
    id: 198,
    data: {
      lat: -22.029733036161332,
      lng: 146.3642232415588,
    },
  },
  199: {
    id: 199,
    data: {
      lat: -22.032796222129953,
      lng: 146.3596312997253,
    },
  },
  200: {
    id: 200,
    data: {
      lat: -22.034546584357077,
      lng: 146.35692763303828,
    },
  },
  201: {
    id: 201,
    data: {
      lat: -22.036973187099633,
      lng: 146.35950255369258,
    },
  },
  202: {
    id: 202,
    data: {
      lat: -22.035700220356176,
      lng: 146.36156249021602,
    },
  },
  214: {
    id: 214,
    data: {
      lat: -22.03280356291623,
      lng: 146.39191257887362,
    },
  },
  216: {
    id: 216,
    data: {
      lat: -22.029494343562522,
      lng: 146.39769721006465,
    },
  },
  217: {
    id: 217,
    data: {
      lat: -22.027743918877306,
      lng: 146.39924216245723,
    },
  },
  218: {
    id: 218,
    data: {
      lat: -22.02583433999914,
      lng: 146.39949965452266,
    },
  },
  219: {
    id: 219,
    data: {
      lat: -22.02379543829654,
      lng: 146.3990047869594,
    },
  },
  220: {
    id: 220,
    data: {
      lat: -22.022194133943604,
      lng: 146.39859575008464,
    },
  },
  221: {
    id: 221,
    data: {
      lat: -22.02082157294772,
      lng: 146.39829266046596,
    },
  },
  222: {
    id: 222,
    data: {
      lat: -22.019588245926826,
      lng: 146.39794397329402,
    },
  },
  223: {
    id: 223,
    data: {
      lat: -22.018394693425705,
      lng: 146.3976328370483,
    },
  },
  224: {
    id: 224,
    data: {
      lat: -22.017837698817484,
      lng: 146.39973568891597,
    },
  },
  242: {
    id: 242,
    data: {
      lat: -22.01933191312074,
      lng: 146.39902534208397,
    },
  },
  244: {
    id: 244,
    data: {
      lat: -22.020605027008994,
      lng: 146.3992828341494,
    },
  },
  246: {
    id: 246,
    data: {
      lat: -22.021997482224013,
      lng: 146.39956178388695,
    },
  },
  248: {
    id: 248,
    data: {
      lat: -22.023549059054496,
      lng: 146.3999480219851,
    },
  },
  250: {
    id: 250,
    data: {
      lat: -22.035461537817365,
      lng: 146.3902299401672,
    },
  },
  251: {
    id: 251,
    data: {
      lat: -22.03633670515885,
      lng: 146.38851332639766,
    },
  },
  252: {
    id: 252,
    data: {
      lat: -22.03575989092801,
      lng: 146.37911486600947,
    },
  },
  253: {
    id: 253,
    data: {
      lat: -22.03550131826845,
      lng: 146.37585329984736,
    },
  },
  263: {
    id: 263,
    data: {
      lat: -22.036975487384105,
      lng: 146.37970328542363,
    },
  },
  264: {
    id: 264,
    data: {
      lat: -22.036995377398313,
      lng: 146.38232112142217,
    },
  },
  265: {
    id: 265,
    data: {
      lat: -22.037771085772505,
      lng: 146.38556122991216,
    },
  },
  266: {
    id: 266,
    data: {
      lat: -22.039183261898277,
      lng: 146.3872993013538,
    },
  },
};

const adjacency = {
  43: [
    {
      id: 215,
      startVertexId: 43,
      endVertexId: 214,
      data: {
        distance: 112.61369147966326,
      },
    },
    {
      id: 225,
      startVertexId: 43,
      endVertexId: 216,
      data: {
        distance: 681.991736434501,
      },
    },
    {
      id: 254,
      startVertexId: 43,
      endVertexId: 250,
      data: {
        distance: 334.2205622080161,
      },
    },
  ],
  54: [
    {
      id: 98,
      startVertexId: 54,
      endVertexId: 90,
      data: {
        distance: 152.08177704317893,
      },
    },
    {
      id: 176,
      startVertexId: 54,
      endVertexId: 174,
      data: {
        distance: 209.53289516672493,
      },
    },
    {
      id: 263,
      startVertexId: 54,
      endVertexId: 253,
      data: {
        distance: 289.25112042753017,
      },
    },
  ],
  55: [
    {
      id: 123,
      startVertexId: 55,
      endVertexId: 117,
      data: {
        distance: 123.32248761749837,
      },
    },
    {
      id: 181,
      startVertexId: 55,
      endVertexId: 175,
      data: {
        distance: 151.62148309541482,
      },
    },
    {
      id: 203,
      startVertexId: 55,
      endVertexId: 197,
      data: {
        distance: 331.08250709388784,
      },
    },
  ],
  90: [
    {
      id: 99,
      startVertexId: 90,
      endVertexId: 54,
      data: {
        distance: 152.08177704317893,
      },
    },
    {
      id: 100,
      startVertexId: 90,
      endVertexId: 91,
      data: {
        distance: 64.73148607445935,
      },
    },
  ],
  91: [
    {
      id: 101,
      startVertexId: 91,
      endVertexId: 90,
      data: {
        distance: 64.73148607445935,
      },
    },
    {
      id: 140,
      startVertexId: 91,
      endVertexId: 134,
      data: {
        distance: 104.5898020755731,
      },
    },
    {
      id: 153,
      startVertexId: 91,
      endVertexId: 139,
      data: {
        distance: 95.76923268786143,
      },
    },
  ],
  117: [
    {
      id: 124,
      startVertexId: 117,
      endVertexId: 55,
      data: {
        distance: 123.32248761749837,
      },
    },
    {
      id: 125,
      startVertexId: 117,
      endVertexId: 118,
      data: {
        distance: 164.2068038141057,
      },
    },
  ],
  118: [
    {
      id: 126,
      startVertexId: 118,
      endVertexId: 117,
      data: {
        distance: 164.2068038141057,
      },
    },
    {
      id: 127,
      startVertexId: 118,
      endVertexId: 119,
      data: {
        distance: 170.23391290834107,
      },
    },
  ],
  119: [
    {
      id: 128,
      startVertexId: 119,
      endVertexId: 118,
      data: {
        distance: 170.23391290834107,
      },
    },
    {
      id: 129,
      startVertexId: 119,
      endVertexId: 120,
      data: {
        distance: 221.80778140258604,
      },
    },
  ],
  120: [
    {
      id: 130,
      startVertexId: 120,
      endVertexId: 119,
      data: {
        distance: 221.80778140258604,
      },
    },
    {
      id: 131,
      startVertexId: 120,
      endVertexId: 121,
      data: {
        distance: 195.09136851071494,
      },
    },
  ],
  121: [
    {
      id: 132,
      startVertexId: 121,
      endVertexId: 120,
      data: {
        distance: 195.09136851071494,
      },
    },
    {
      id: 133,
      startVertexId: 121,
      endVertexId: 122,
      data: {
        distance: 85.09086869447363,
      },
    },
  ],
  122: [
    {
      id: 134,
      startVertexId: 122,
      endVertexId: 121,
      data: {
        distance: 85.09086869447363,
      },
    },
  ],
  134: [
    {
      id: 141,
      startVertexId: 134,
      endVertexId: 91,
      data: {
        distance: 104.5898020755731,
      },
    },
    {
      id: 142,
      startVertexId: 134,
      endVertexId: 135,
      data: {
        distance: 63.97116538432484,
      },
    },
  ],
  135: [
    {
      id: 143,
      startVertexId: 135,
      endVertexId: 134,
      data: {
        distance: 63.97116538432484,
      },
    },
    {
      id: 144,
      startVertexId: 135,
      endVertexId: 136,
      data: {
        distance: 163.2583219378,
      },
    },
    {
      id: 158,
      startVertexId: 135,
      endVertexId: 153,
      data: {
        distance: 59.71770179905911,
      },
    },
  ],
  136: [
    {
      id: 145,
      startVertexId: 136,
      endVertexId: 135,
      data: {
        distance: 163.2583219378,
      },
    },
    {
      id: 146,
      startVertexId: 136,
      endVertexId: 137,
      data: {
        distance: 246.715039787231,
      },
    },
  ],
  137: [
    {
      id: 147,
      startVertexId: 137,
      endVertexId: 136,
      data: {
        distance: 246.715039787231,
      },
    },
    {
      id: 148,
      startVertexId: 137,
      endVertexId: 138,
      data: {
        distance: 129.55910151249861,
      },
    },
    {
      id: 169,
      startVertexId: 137,
      endVertexId: 157,
      data: {
        distance: 40.23392263187554,
      },
    },
  ],
  138: [
    {
      id: 149,
      startVertexId: 138,
      endVertexId: 137,
      data: {
        distance: 129.55910151249861,
      },
    },
    {
      id: 150,
      startVertexId: 138,
      endVertexId: 139,
      data: {
        distance: 561.6450663396762,
      },
    },
  ],
  139: [
    {
      id: 151,
      startVertexId: 139,
      endVertexId: 138,
      data: {
        distance: 561.6450663396762,
      },
    },
    {
      id: 152,
      startVertexId: 139,
      endVertexId: 91,
      data: {
        distance: 95.76923268786143,
      },
    },
    {
      id: 171,
      startVertexId: 139,
      endVertexId: 169,
      data: {
        distance: 231.16120837730546,
      },
    },
  ],
  153: [
    {
      id: 159,
      startVertexId: 153,
      endVertexId: 135,
      data: {
        distance: 59.71770179905911,
      },
    },
    {
      id: 160,
      startVertexId: 153,
      endVertexId: 154,
      data: {
        distance: 113.51842034696905,
      },
    },
  ],
  154: [
    {
      id: 161,
      startVertexId: 154,
      endVertexId: 153,
      data: {
        distance: 113.51842034696905,
      },
    },
    {
      id: 162,
      startVertexId: 154,
      endVertexId: 155,
      data: {
        distance: 48.064590495233006,
      },
    },
  ],
  155: [
    {
      id: 163,
      startVertexId: 155,
      endVertexId: 154,
      data: {
        distance: 48.064590495233006,
      },
    },
    {
      id: 164,
      startVertexId: 155,
      endVertexId: 156,
      data: {
        distance: 155.7732045857018,
      },
    },
  ],
  156: [
    {
      id: 165,
      startVertexId: 156,
      endVertexId: 155,
      data: {
        distance: 155.7732045857018,
      },
    },
    {
      id: 166,
      startVertexId: 156,
      endVertexId: 157,
      data: {
        distance: 82.53547938917166,
      },
    },
  ],
  157: [
    {
      id: 167,
      startVertexId: 157,
      endVertexId: 156,
      data: {
        distance: 82.53547938917166,
      },
    },
    {
      id: 168,
      startVertexId: 157,
      endVertexId: 137,
      data: {
        distance: 40.23392263187554,
      },
    },
  ],
  169: [
    {
      id: 172,
      startVertexId: 169,
      endVertexId: 139,
      data: {
        distance: 231.16120837730546,
      },
    },
    {
      id: 173,
      startVertexId: 169,
      endVertexId: 170,
      data: {
        distance: 185.2042060835836,
      },
    },
  ],
  170: [
    {
      id: 174,
      startVertexId: 170,
      endVertexId: 169,
      data: {
        distance: 185.2042060835836,
      },
    },
  ],
  174: [
    {
      id: 177,
      startVertexId: 174,
      endVertexId: 54,
      data: {
        distance: 209.53289516672493,
      },
    },
    {
      id: 178,
      startVertexId: 174,
      endVertexId: 175,
      data: {
        distance: 102.47133068430065,
      },
    },
    {
      id: 192,
      startVertexId: 174,
      endVertexId: 189,
      data: {
        distance: 171.78830618405323,
      },
    },
  ],
  175: [
    {
      id: 179,
      startVertexId: 175,
      endVertexId: 174,
      data: {
        distance: 102.47133068430065,
      },
    },
    {
      id: 180,
      startVertexId: 175,
      endVertexId: 55,
      data: {
        distance: 151.62148309541482,
      },
    },
    {
      id: 184,
      startVertexId: 175,
      endVertexId: 181,
      data: {
        distance: 83.07755597325104,
      },
    },
  ],
  181: [
    {
      id: 185,
      startVertexId: 181,
      endVertexId: 175,
      data: {
        distance: 83.07755597325104,
      },
    },
    {
      id: 186,
      startVertexId: 181,
      endVertexId: 182,
      data: {
        distance: 188.4628879082528,
      },
    },
  ],
  182: [
    {
      id: 187,
      startVertexId: 182,
      endVertexId: 181,
      data: {
        distance: 188.4628879082528,
      },
    },
    {
      id: 188,
      startVertexId: 182,
      endVertexId: 183,
      data: {
        distance: 219.44719105311907,
      },
    },
  ],
  183: [
    {
      id: 189,
      startVertexId: 183,
      endVertexId: 182,
      data: {
        distance: 219.44719105311907,
      },
    },
  ],
  189: [
    {
      id: 193,
      startVertexId: 189,
      endVertexId: 174,
      data: {
        distance: 171.78830618405323,
      },
    },
    {
      id: 194,
      startVertexId: 189,
      endVertexId: 190,
      data: {
        distance: 152.86293873328685,
      },
    },
  ],
  190: [
    {
      id: 195,
      startVertexId: 190,
      endVertexId: 189,
      data: {
        distance: 152.86293873328685,
      },
    },
    {
      id: 196,
      startVertexId: 190,
      endVertexId: 191,
      data: {
        distance: 248.8984588056902,
      },
    },
  ],
  191: [
    {
      id: 197,
      startVertexId: 191,
      endVertexId: 190,
      data: {
        distance: 248.8984588056902,
      },
    },
  ],
  197: [
    {
      id: 204,
      startVertexId: 197,
      endVertexId: 55,
      data: {
        distance: 331.08250709388784,
      },
    },
    {
      id: 205,
      startVertexId: 197,
      endVertexId: 198,
      data: {
        distance: 294.0901747925526,
      },
    },
  ],
  198: [
    {
      id: 206,
      startVertexId: 198,
      endVertexId: 197,
      data: {
        distance: 294.0901747925526,
      },
    },
    {
      id: 207,
      startVertexId: 198,
      endVertexId: 199,
      data: {
        distance: 583.13285056415,
      },
    },
  ],
  199: [
    {
      id: 208,
      startVertexId: 199,
      endVertexId: 198,
      data: {
        distance: 583.13285056415,
      },
    },
    {
      id: 209,
      startVertexId: 199,
      endVertexId: 200,
      data: {
        distance: 339.9148825758566,
      },
    },
  ],
  200: [
    {
      id: 210,
      startVertexId: 200,
      endVertexId: 199,
      data: {
        distance: 339.9148825758566,
      },
    },
    {
      id: 211,
      startVertexId: 200,
      endVertexId: 201,
      data: {
        distance: 378.47659264645534,
      },
    },
  ],
  201: [
    {
      id: 212,
      startVertexId: 201,
      endVertexId: 200,
      data: {
        distance: 378.47659264645534,
      },
    },
    {
      id: 213,
      startVertexId: 201,
      endVertexId: 202,
      data: {
        distance: 255.17828300911503,
      },
    },
  ],
  202: [
    {
      id: 214,
      startVertexId: 202,
      endVertexId: 201,
      data: {
        distance: 255.17828300911503,
      },
    },
  ],
  214: [
    {
      id: 216,
      startVertexId: 214,
      endVertexId: 43,
      data: {
        distance: 112.61369147966326,
      },
    },
  ],
  216: [
    {
      id: 226,
      startVertexId: 216,
      endVertexId: 43,
      data: {
        distance: 681.991736434501,
      },
    },
    {
      id: 227,
      startVertexId: 216,
      endVertexId: 217,
      data: {
        distance: 251.4846034378793,
      },
    },
  ],
  217: [
    {
      id: 228,
      startVertexId: 217,
      endVertexId: 216,
      data: {
        distance: 251.4846034378793,
      },
    },
    {
      id: 229,
      startVertexId: 217,
      endVertexId: 218,
      data: {
        distance: 213.9879244137962,
      },
    },
  ],
  218: [
    {
      id: 230,
      startVertexId: 218,
      endVertexId: 217,
      data: {
        distance: 213.9879244137962,
      },
    },
    {
      id: 231,
      startVertexId: 218,
      endVertexId: 219,
      data: {
        distance: 232.38341338755987,
      },
    },
  ],
  219: [
    {
      id: 232,
      startVertexId: 219,
      endVertexId: 218,
      data: {
        distance: 232.38341338755987,
      },
    },
    {
      id: 233,
      startVertexId: 219,
      endVertexId: 220,
      data: {
        distance: 182.98108672264888,
      },
    },
    {
      id: 249,
      startVertexId: 219,
      endVertexId: 248,
      data: {
        distance: 101.01549478142654,
      },
    },
  ],
  220: [
    {
      id: 234,
      startVertexId: 220,
      endVertexId: 219,
      data: {
        distance: 182.98108672264888,
      },
    },
    {
      id: 235,
      startVertexId: 220,
      endVertexId: 221,
      data: {
        distance: 155.7869039065776,
      },
    },
    {
      id: 247,
      startVertexId: 220,
      endVertexId: 246,
      data: {
        distance: 101.95332183329026,
      },
    },
  ],
  221: [
    {
      id: 236,
      startVertexId: 221,
      endVertexId: 220,
      data: {
        distance: 155.7869039065776,
      },
    },
    {
      id: 237,
      startVertexId: 221,
      endVertexId: 222,
      data: {
        distance: 141.77186446502222,
      },
    },
    {
      id: 245,
      startVertexId: 221,
      endVertexId: 244,
      data: {
        distance: 104.87184685566366,
      },
    },
  ],
  222: [
    {
      id: 238,
      startVertexId: 222,
      endVertexId: 221,
      data: {
        distance: 141.77186446502222,
      },
    },
    {
      id: 239,
      startVertexId: 222,
      endVertexId: 223,
      data: {
        distance: 136.53751216628237,
      },
    },
    {
      id: 243,
      startVertexId: 222,
      endVertexId: 242,
      data: {
        distance: 115.05815649216402,
      },
    },
  ],
  223: [
    {
      id: 240,
      startVertexId: 223,
      endVertexId: 222,
      data: {
        distance: 136.53751216628237,
      },
    },
    {
      id: 241,
      startVertexId: 223,
      endVertexId: 224,
      data: {
        distance: 225.44671054273005,
      },
    },
  ],
  224: [
    {
      id: 242,
      startVertexId: 224,
      endVertexId: 223,
      data: {
        distance: 225.44671054273005,
      },
    },
  ],
  242: [
    {
      id: 244,
      startVertexId: 242,
      endVertexId: 222,
      data: {
        distance: 115.05815649216402,
      },
    },
  ],
  244: [
    {
      id: 246,
      startVertexId: 244,
      endVertexId: 221,
      data: {
        distance: 104.87184685566366,
      },
    },
  ],
  246: [
    {
      id: 248,
      startVertexId: 246,
      endVertexId: 220,
      data: {
        distance: 101.95332183329026,
      },
    },
  ],
  248: [
    {
      id: 250,
      startVertexId: 248,
      endVertexId: 219,
      data: {
        distance: 101.01549478142654,
      },
    },
  ],
  250: [
    {
      id: 255,
      startVertexId: 250,
      endVertexId: 43,
      data: {
        distance: 334.2205622080161,
      },
    },
    {
      id: 256,
      startVertexId: 250,
      endVertexId: 251,
      data: {
        distance: 201.93065404462465,
      },
    },
  ],
  251: [
    {
      id: 257,
      startVertexId: 251,
      endVertexId: 250,
      data: {
        distance: 201.93065404462465,
      },
    },
    {
      id: 258,
      startVertexId: 251,
      endVertexId: 252,
      data: {
        distance: 970.8382861073887,
      },
    },
  ],
  252: [
    {
      id: 259,
      startVertexId: 252,
      endVertexId: 251,
      data: {
        distance: 970.8382861073887,
      },
    },
    {
      id: 260,
      startVertexId: 252,
      endVertexId: 253,
      data: {
        distance: 337.404140291152,
      },
    },
    {
      id: 267,
      startVertexId: 252,
      endVertexId: 263,
      data: {
        distance: 148.1512003726915,
      },
    },
  ],
  253: [
    {
      id: 261,
      startVertexId: 253,
      endVertexId: 252,
      data: {
        distance: 337.404140291152,
      },
    },
    {
      id: 262,
      startVertexId: 253,
      endVertexId: 54,
      data: {
        distance: 289.25112042753017,
      },
    },
  ],
  263: [
    {
      id: 268,
      startVertexId: 263,
      endVertexId: 252,
      data: {
        distance: 148.1512003726915,
      },
    },
    {
      id: 269,
      startVertexId: 263,
      endVertexId: 264,
      data: {
        distance: 269.8326419377056,
      },
    },
  ],
  264: [
    {
      id: 270,
      startVertexId: 264,
      endVertexId: 263,
      data: {
        distance: 269.8326419377056,
      },
    },
    {
      id: 271,
      startVertexId: 264,
      endVertexId: 265,
      data: {
        distance: 344.9200875152646,
      },
    },
  ],
  265: [
    {
      id: 272,
      startVertexId: 265,
      endVertexId: 264,
      data: {
        distance: 344.9200875152646,
      },
    },
    {
      id: 273,
      startVertexId: 265,
      endVertexId: 266,
      data: {
        distance: 238.22202913102805,
      },
    },
  ],
  266: [
    {
      id: 274,
      startVertexId: 266,
      endVertexId: 265,
      data: {
        distance: 238.22202913102805,
      },
    },
  ],
};

export function createTempGraph() {
  return fromGraph(vertices, adjacency);
}
