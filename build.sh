#!/bin/bash
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
set -e

echo =============================17.10================================
echo "Build vpp SRPM for 17.10 release"

bash -x build-vpp-srpm.sh -g stable/1710

bash -x clean.sh

exit 0
