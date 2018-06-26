<template>
  <div>
    <div id="nav-toggle">
      <button id="nav-toggle-btn" @click="toggleNav">
        <span class="nav-toggle-icon-wrapper">
          <svg viewBox="0 0 22 22" class="nav-toggle-icon" >
            <g>
              <path stroke-miterlimit="10" d="M0 4.5h22m-22 6h22m-22 6h22">
              </path>
            </g>
          </svg>
        </span>
      </button>
    </div>

    <span id="nav-gap"/>

    <div id="nav-bar" :class="smallShowNav">
      <div v-for="route in routes" :key="route.path">
        <router-link v-if="route.path !== '*'" :to="route.path" class="nav-item">
          <div :id="route.path" @click.capture="closeNav" class="nav-item-wrapper" >
            <div class="nav-icon-wrapper">
              <icon :icon="route.icon" :icon_size="route.icon_size"/>
            </div>
            <p class="nav-label">
              {{route.name}}
            </p>
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>

<script>
import icon from '../Icon.vue'

export default {
  name: 'hxNavbar',
  props: {
    routes: Array
  },
  data: () => {
    return { smallShowNav: "hideNav" };
  },
  methods: {
    toggleNav: function() {
      if(this.smallShowNav === "hideNav")
        this.smallShowNav = "showNav";
      else
        this.smallShowNav = "hideNav";
    },
    closeNav: function() {
      this.smallShowNav = "hideNav";
    }
  },
  components: {
    icon
  }
}

</script>

<style>
.router-link-active .nav-item-wrapper {
  background-color: #1b2a33;
  border-left-color: #09819c;
  border-left-width: 0.15em;
  border-left-style: solid;
}

.nav-item-wrapper:hover {
  background-color: #23343f
}

.nav-label {
  margin: auto;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  flex: 1 1 auto;
  display: block;
}

.nav-item-wrapper {
  display: flex;
  overflow: hidden;
  background-color: #0c1419;
  height: 4em;
  width: 100%;

  white-space: nowrap;
  color: #b7c3cd;
}

.nav-item {
  text-decoration: none;
}

#nav-bar:hover {
  overflow: hidden;
  overflow-y: auto;
  max-width: 21.33333rem;
}

#nav-bar {
  overflow: hidden;
  background-color: #1B2A33;
  z-index: 5;
  box-sizing: inherit;
  verflow-x: hidden;
  overflow-y: hidden;
  position: absolute;
  height: 100%;
  left: 0;
  top: 0;
  min-width: 4rem;
  max-width: 4rem;
  transition: max-width 250ms ease;
  outline: 0;
  box-shadow: 0 2px 4px rgba(0,0,0,.2);
  width: 100%;
  line-height: 1.33333;
  color: #b6c3cc;
}

.nav-icon-wrapper {
  width: 3.8rem;
  min-width: 3.8rem;
  height: 4rem;
  margin-right: .33333rem;
  display: flex;
  align-items: center; 
}

.nav-toggle-icon {
  pointer-events: none;
  display: block;
  width: 100%;
  height: 100%;
}

.nav-toggle-icon-wrapper {
  fill: none;
  height: 2em;
  width: 3em;
  position: relative;
  display: flex;
}

#nav-toggle {
  display: none;
  position: absolute;
  left: 1em;
  top: -3em;
}

#nav-toggle-btn {
  color: #b7c3cd;
  stroke: #b7c3cd;
  -webkit-appearance: button;
  max-width: 12rem;
  display: flex;
  align-items: center;
  margin-left: auto;
  margin-right: auto;
  line-height: 2rem;
  box-shadow: none;
  background: 0 0;
  outline: 0;
  border: 0!important;
  border-radius: 0!important;
  padding-left: 0;
  padding-right: 0;
  overflow: visible;
  min-width: 4.66667em;
  margin: 0;
  height: 2em;
  padding: 0 calc(2em/ 2);
  text-align: center;
  text-transform: none;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
}

@media screen and (max-width: 820px) {
  #nav-bar {
    max-width: 100%
  }

  #nav-bar:hover {
    max-width: 100%
  }

  #nav-toggle {
    display: block;
  }

  .hideNav {
    display: none;
  }

  #nav-gap {
    display: none;
  }
}
</style>
