// use https://github.com/predixdesignsystem/px-icon-set as a reference
//
// NOTE: use " instead of '. Makes it easier to adapt the reference

export default (iconName) => {
  switch(iconName) {
    case "generic-user":
      return {
        size: 22,
        shapes: [
          {
            type:"path",
            d:"M16.17 12l4.33 3v6.5h-19V15l4.33-3"
          },
          {
            type:"rect",
            x:"6.5",
            y:".5",
            width:"9",
            height:"11",
            rx:"4.5",
            ry:"4.5",
            strokeLinejoin:"round"
          }
        ]
      }
    default:
      throw new Error(`Could not find Shape with name ${iconName}`);
  }
};
