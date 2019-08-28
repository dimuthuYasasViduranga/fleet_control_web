<template>
  <footer role="banner">
    <div id="footer-wrapper">
      <span> ©2018 - {{ now }} Haultrax </span>
    </div>
  </footer>
</template>

<script>
export default {
  name: 'hxFooter',
  computed: {
    now() {
      const now = new Date();
      return now.getFullYear();
    },
  },
};
</script>

<style>
footer span {
  align: right;
  display: block;
  -webkit-margin-after: 12px;
  -webkit-margin-before: 12px;
}

#footer-wrapper {
  margin-left: auto;
  align-items: center;
  -webkit-box-pack: justify;
  -webkit-box-align: center;
  -webkit-font-smoothing: antialiased;
  -ms-flex-pack: justify;
  -ms-flex-align: center;
  justify-content: space-between;
  display: flex;
  width: auto;
  max-width: none;
  padding-left: 2em;
  padding-right: 2em;
}

footer {
  box-sizing: border-box;
  line-height: 19.9999px;
  width: 100%;
  display: flex;
  margin: auto;
  height: 4rem;
  background-color: #0c1419;
  -webkit-box-align: center;
  align-items: center;
  font-size: 12px;
}
</style>
