webpackJsonp([0],{0:function(t,e,r){t.exports=r("eitI")},"6dCs":function(t,e){},"7KLG":function(t,e){},OLkD:function(t,e){},eitI:function(t,e,r){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var a=r("fAfE"),n={name:"hxHeader",props:{username:String,logoutUrl:String}},s=function(){var t=this,e=t.$createElement,a=t._self._c||e;return a("header",{attrs:{role:"banner"}},[a("div",{attrs:{id:"header-wrapper"}},[a("img",{attrs:{id:"logo",src:r("v/qA")}}),a("span",{attrs:{id:"login"}},[a("button",{attrs:{id:"login-btn"}},[a("span",{staticClass:"icon-wrapper"},[a("svg",{staticClass:"icon",attrs:{viewBox:"0 0 22 22"}},[a("g",[a("path",{attrs:{"stroke-linejoin":"round",d:"M16.17 12l4.33 3v6.5h-19V15l4.33-3"}}),a("rect",{attrs:{x:"6.5",y:".5",width:"9",height:"11",rx:"4.5",ry:"4.5","stroke-linejoin":"round"}})])])]),t._v("\n\n        "+t._s(t.username||"Sign in")+"\n\n        "),a("span",{staticClass:"icon-wrapper"},[a("svg",{staticClass:"icon",attrs:{viewBox:"0 0 16 16"}},[a("g",[a("path",{attrs:{"stroke-linejoin":"round",d:"M2.4 6.2l5.5 5.5 5.5-5.5"}})])])])])])])])},i=[],o=r("xRi5");function l(t){r("6dCs")}var u=!1,c=l,A=null,v=null,h=Object(o["a"])(n,s,i,u,c,A,v),p=h.exports,f=this,g={name:"hxNavbar",props:{routes:Array,selected:String},methods:{changeSelected:function(t){f.selected=t.target.id,console.log(f.selected)}}},d=function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("div",[r("span",{attrs:{id:"nav-gap"}}),r("div",{attrs:{id:"nav-bar"}},t._l(t.routes,function(e){return r("div",{key:e.path},[r("router-link",{staticClass:"nav-item",attrs:{to:e.path}},[r("div",{staticClass:"nav-item-wrapper",attrs:{id:e.path}},[r("span",{domProps:{innerHTML:t._s(e.icon)}}),t._v("\n          "+t._s(e.name)+"\n        ")])])],1)}))])},m=[];function b(t){r("OLkD")}var x=!1,E=b,j=null,k=null,y=Object(o["a"])(g,d,m,x,E,j,k),_=y.exports,L={name:"hxFooter"},w=function(){var t=this,e=t.$createElement;t._self._c;return t._m(0)},S=[function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("footer",{attrs:{role:"banner"}},[r("div",{attrs:{id:"footer-wrapper"}},[r("span",[t._v("\n      ©2018 Haultrax\n    ")])])])}];function C(t){r("zRYg")}var I=!1,R=C,V=null,F=null,H=Object(o["a"])(L,w,S,I,R,V,F),Y=H.exports,B={name:"Layout",props:{routes:Array},created:function(){console.log(this)},components:{hxHeader:p,hxNavbar:_,hxFooter:Y}},J=function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("div",{attrs:{id:"layout"}},[r("hxHeader"),r("div",{attrs:{id:"body"}},[r("hxNavbar",{attrs:{routes:t.routes}}),r("span",{attrs:{id:"nav-gap"}}),r("router-view",{staticClass:"view"})],1),r("hxFooter")],1)},M=[];function W(t){r("jif0")}var T=!1,U=W,O=null,K=null,X=Object(o["a"])(B,J,M,T,U,O,K),P=X.exports,z={name:"app",props:{routes:Array},components:{Layout:P}},D=function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("div",[r("Layout",{attrs:{routes:t.routes}})],1)},N=[],Q=!1,Z=null,q=null,G=null,$=Object(o["a"])(z,D,N,Q,Z,q,G),tt=$.exports,et=r("7ov2"),rt={name:"HelloWorld",props:{msg:String}},at=function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("div",{staticClass:"hello"},[r("h1",[t._v(t._s(t.msg))]),t._m(0),r("h3",[t._v("Installed CLI Plugins")]),t._m(1),r("h3",[t._v("Essential Links")]),t._m(2),r("h3",[t._v("Ecosystem")]),t._m(3)])},nt=[function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("p",[t._v("\n    For guide and recipes on how to configure / customize this project,"),r("br"),t._v("\n    check out the\n    "),r("a",{attrs:{href:"https://github.com/vuejs/vue-cli/tree/dev/docs",target:"_blank"}},[t._v("vue-cli documentation")]),t._v(".\n  ")])},function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("ul",[r("li",[r("a",{attrs:{href:"https://github.com/vuejs/vue-cli/tree/dev/packages/%40vue/cli-plugin-babel",target:"_blank"}},[t._v("babel")])]),r("li",[r("a",{attrs:{href:"https://github.com/vuejs/vue-cli/tree/dev/packages/%40vue/cli-plugin-eslint",target:"_blank"}},[t._v("eslint")])])])},function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("ul",[r("li",[r("a",{attrs:{href:"https://vuejs.org",target:"_blank"}},[t._v("Core Docs")])]),r("li",[r("a",{attrs:{href:"https://forum.vuejs.org",target:"_blank"}},[t._v("Forum")])]),r("li",[r("a",{attrs:{href:"https://chat.vuejs.org",target:"_blank"}},[t._v("Community Chat")])]),r("li",[r("a",{attrs:{href:"https://twitter.com/vuejs",target:"_blank"}},[t._v("Twitter")])])])},function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("ul",[r("li",[r("a",{attrs:{href:"https://router.vuejs.org/en/essentials/getting-started.html",target:"_blank"}},[t._v("vue-router")])]),r("li",[r("a",{attrs:{href:"https://vuex.vuejs.org/en/intro.html",target:"_blank"}},[t._v("vuex")])]),r("li",[r("a",{attrs:{href:"https://github.com/vuejs/vue-devtools#vue-devtools",target:"_blank"}},[t._v("vue-devtools")])]),r("li",[r("a",{attrs:{href:"https://vue-loader.vuejs.org/en",target:"_blank"}},[t._v("vue-loader")])]),r("li",[r("a",{attrs:{href:"https://github.com/vuejs/awesome-vue",target:"_blank"}},[t._v("awesome-vue")])])])}];function st(t){r("nAYc")}var it=!1,ot=st,lt="data-v-8b3cb954",ut=null,ct=Object(o["a"])(rt,at,nt,it,ot,lt,ut),At=ct.exports,vt={name:"HelloGalaxy",props:{msg:String}},ht=function(){var t=this,e=t.$createElement,r=t._self._c||e;return r("div",{staticClass:"hello"},[r("h1",[t._v(t._s(t.msg))]),t._v("\n  This is much more sparse.\n")])},pt=[];function ft(t){r("7KLG")}var gt=!1,dt=ft,mt="data-v-87c5e006",bt=null,xt=Object(o["a"])(vt,ht,pt,gt,dt,mt,bt),Et=xt.exports;a["a"].config.productionTip=!1,a["a"].use(et["a"]);var jt=[{name:"Hello World",path:"/hello-world",component:At},{name:"Hello Galaxy",path:"/hello-galaxy",component:Et}],kt=new et["a"]({routes:jt}),yt={routes:jt};new a["a"]({el:"#app",router:kt,render:function(t){return t(tt,{props:yt})},data:{routes:jt}})},jif0:function(t,e){},nAYc:function(t,e){},"v/qA":function(t,e){t.exports="data:image/png;base64,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"},zRYg:function(t,e){}},[0]);
//# sourceMappingURL=app.061d492d.js.map