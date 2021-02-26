import React from "react";
import { message, Spin } from "antd";
import { getHitokoto } from "./api/hitokoto";

export default class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      hitokoto: "",
    };
  }

  componentDidMount() {
    this.setState({
      loading: true,
    });
    getHitokoto()
      .then((res) => {
        const data = res.data;
        if (data.code !== 200) {
          message.error(data.err);
          return;
        }
        this.setState({
          hitokoto: data.hitokoto,
        });
      })
      .catch((err) => {
        message.error(err);
      })
      .finally(() => {
        this.setState({
          loading: false,
        });
      });
  }

  render() {
    return (
      <Spin spinning={this.state.loading} delay={500}>
        <h2 style={{textAlign: "center"}}>{this.state.hitokoto}</h2>
      </Spin>
    );
  }
}
