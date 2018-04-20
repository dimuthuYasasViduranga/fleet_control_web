<template>
  <div>
    <span id="nav-gap"/>
    <div id="nav-bar">
      <div v-for="route in routes" :key="route.path">
        <router-link v-if="route.path !== '*'" :to="route.path" class="nav-item">
          <div :id="route.path" class="nav-item-wrapper" >
            <div class="nav-icon-wrapper">
              <icon :icon="route.icon"/>
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
  display: block;
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
</style>
