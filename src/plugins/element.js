import Vue from 'vue'
import {
  Button,
  Form, FormItem,
  Tabs, TabPane,
  Input, InputNumber,
  RadioButton, RadioGroup,
  Switch,
  Row, Col
} from 'element-ui'
import lang from 'element-ui/lib/locale/lang/ja'
import locale from 'element-ui/lib/locale'

locale.use(lang)

Vue.use(Button)
Vue.use(Form)
Vue.use(FormItem)
Vue.use(Tabs)
Vue.use(TabPane)
Vue.use(Input)
Vue.use(InputNumber)
Vue.use(RadioButton)
Vue.use(RadioGroup)
Vue.use(Switch)
Vue.use(Row)
Vue.use(Col)
