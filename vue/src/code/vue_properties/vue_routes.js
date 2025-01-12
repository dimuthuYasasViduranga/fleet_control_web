import VueRouter from 'vue-router';

import AssetAssignment from '../../components/pages/asset_assignment/AssetAssignment.vue';
import AssetStatus from '../../components/pages/asset_status/AssetStatus.vue';
import DeviceAssignment from '../../components/pages/device_assignment/DeviceAssignment.vue';
import LocationAssignment from '../../components/pages/location_assignment/LocationAssignment.vue';
import Operators from '../../components/pages/operators/Operators.vue';
import TimeAllocationPage from '../../components/pages/time_allocation/TimeAllocationPage.vue';
import TimeAllocationReport from '../../components/pages/time_allocation_report/TimeAllocationReport.vue';
import TimeCodeEditorPage from '../../components/pages/time_code_editor/TimeCodeEditorPage.vue';
import OperatorTimeAllocationPage from '../../components/pages/operator_time_allocation/OperatorTimeAllocationPage.vue';
import MessageEditorPage from '../../components/pages/message_editor/MessageEditorPage.vue';
import MineMap from '../../components/pages/mine_map/MineMap.vue';
import RouteMapPage from '../../components/pages/route_map/RouteMapPage.vue';
import EngineHours from '../../components/pages/engine_hours/EngineHours.vue';
import Debug from '../../components/pages/debug/Debug2.vue';
import Agents from '../../components/pages/agents/Agents.vue';
import PreStartEditor from '../../components/pages/pre_start_editor/PreStartEditor.vue';
import PreStartSubmissionsPage from '../../components/pages/pre_start_submissions/PreStartSubmissionsPage.vue';
import AssetOverviewPage from '../../components/pages/asset_overview/AssetOverviewPage.vue';
import AssetRosterPage from '../../components/pages/asset_roster/AssetRosterPage.vue';

import HaulTruckIcon from '../../components/icons/asset_icons/HaulTruck.vue';
import TabletIcon from '../../components/icons/Tablet.vue';
import LocationIcon from '../../components/icons/Location.vue';
import ManIcon from '../../components/icons/Man.vue';
import LineIcon from '../../components/icons/Line.vue';
import ClockWithTruckIcon from '../../components/icons/ClockWithTruck.vue';
import ClockWithUserIcon from '../../components/icons/ClockWithUser.vue';
import MapIcon from '../../components/icons/Map.vue';
import PlaneEngineIcon from '../../components/icons/PlaneEngine.vue';
import NestedListIcon from '../../components/icons/NestedList.vue';
import BugIcon from '../../components/icons/Bug.vue';
import DatabaseIcon from '../../components/icons/Database.vue';
import ReportIcon from '../../components/icons/Report.vue';
import ChatIcon from '../../components/icons/Chat.vue';
import GridIcon from '../../components/icons/Grid.vue';
import CogIcon from '../../components/icons/Cog.vue';

import Vue from 'vue';

const DEFAULT_ROUTE = '/location_assignment';
const ASSET_TRUCK_VIEW_BOX = [0, 4, 34, 26];

Vue.use(VueRouter);

export default function setupRouter(whitelist) {
  let routes = [
    {
      name: 'Asset Assignment',
      path: '/asset_assignment',
      component: AssetAssignment,
      icon: HaulTruckIcon,
      iconProps: {
        viewBox: ASSET_TRUCK_VIEW_BOX,
      },
    },
    {
      name: 'Location Assignment',
      path: '/location_assignment',
      component: LocationAssignment,
      icon: LocationIcon,
    },
    {
      name: 'Asset Overview',
      path: '/asset_overview',
      component: AssetOverviewPage,
      icon: GridIcon,
    },
    {
      name: 'Mine Map',
      path: '/mine_map',
      component: MineMap,
      icon: MapIcon,
    },
    {
      name: 'Route Map',
      path: '/route_map',
      component: RouteMapPage,
      icon: LineIcon,
    },
    { path: '/gap_1', gap: true },
    {
      name: 'Operators',
      path: '/operators',
      component: Operators,
      icon: ManIcon,
    },
    { name: 'Asset Roster', path: '/asset_roster', component: AssetRosterPage, icon: CogIcon },
    {
      name: 'Device Assignment',
      path: '/device_assignment',
      component: DeviceAssignment,
      icon: TabletIcon,
    },
    {
      name: 'Time Code Editor',
      path: '/time_code_editor',
      component: TimeCodeEditorPage,
      icon: NestedListIcon,
    },
    {
      name: 'Message Editor',
      path: '/message_editor',
      component: MessageEditorPage,
      icon: ChatIcon,
    },
    {
      name: 'Pre-Start Editor',
      path: '/pre_start_editor',
      component: PreStartEditor,
      icon: ReportIcon,
    },
    { path: '/gap_2', gap: true },
    {
      name: 'Asset Status',
      path: '/asset_status',
      component: AssetStatus,
      icon: HaulTruckIcon,
      iconProps: {
        viewBox: ASSET_TRUCK_VIEW_BOX,
      },
    },
    {
      name: 'Pre-Start Submissions',
      path: '/pre_start_submissions',
      component: PreStartSubmissionsPage,
      icon: ReportIcon,
    },
    {
      name: 'Engine Hours',
      path: '/engine_hours',
      component: EngineHours,
      icon: PlaneEngineIcon,
    },
    {
      name: 'Time Allocation',
      path: '/time_allocation',
      component: TimeAllocationPage,
      icon: ClockWithTruckIcon,
    },
    {
      name: 'Operator Time Allocation',
      path: '/operator_time_allocation',
      component: OperatorTimeAllocationPage,
      icon: ClockWithUserIcon,
    },
    {
      name: 'Time Allocation Report',
      path: '/time_allocation_report',
      component: TimeAllocationReport,
      icon: ReportIcon,
    },
    { path: '/gap_3', gap: true },
    {
      name: 'Debug',
      path: '/debug',
      component: Debug,
      icon: BugIcon,
    },
    {
      name: 'Agents',
      path: '/agents',
      component: Agents,
      icon: DatabaseIcon,
    },
  ];

  // @ts-ignore
  routes = routes.filter(r => r.gap === true || whitelist.includes(r.path));

  // set default page, or the first available
  if (routes.length !== 0) {
    if (routes.find(r => r.path === DEFAULT_ROUTE)) {
      routes.push({ path: '*', redirect: DEFAULT_ROUTE });
    } else {
      routes.push({ path: '*', redirect: routes[0].path });
    }
  }

  const router = new VueRouter({ routes });

  return [routes, router];
}
